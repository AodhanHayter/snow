use crate::flake::{self, Delta};
use crate::host::{self, Os};
use crate::runner::{self, Event, Line};
use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use crossterm::event::{self, KeyCode, KeyEvent, KeyEventKind, KeyModifiers};
use crossterm::execute;
use crossterm::terminal::{
    disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen,
};
use ratatui::backend::CrosstermBackend;
use ratatui::layout::{Alignment, Constraint, Direction, Layout, Rect};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line as TLine, Span};
use ratatui::widgets::{
    Block, Borders, Cell, Clear, Gauge, Padding, Paragraph, Row, Table, Wrap,
};
use ratatui::{Frame, Terminal};
use std::collections::VecDeque;
use std::io;
use std::path::PathBuf;
use std::process::{Command, ExitStatus};
use std::sync::mpsc::{self, Receiver, Sender};
use std::thread;
use std::time::{Duration, Instant};

const LOG_TAIL: usize = 256;
const SPIN: [&str; 10] = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

pub struct Config {
    pub flake_dir: PathBuf,
    pub host: String,
    pub os: Os,
    pub no_rebuild: bool,
}

struct App {
    cfg: Config,
    phase: Phase,
    started: Instant,
    backup_lock: String,
    exit_message: Option<String>,
}

enum Phase {
    Updating(Updating),
    Review(Review),
    Applying(Applying),
    Rebuilding(Rebuilding),
    Done(Done),
}

struct Updating {
    stream: runner::Stream,
    log: VecDeque<String>,
    finished: bool,
    error: Option<String>,
}

struct Review {
    deltas: Vec<Delta>,
    selected: Vec<bool>,
    cursor: usize,
    diff: Option<usize>,
}

struct Applying {
    rx: Receiver<Event>,
    log: VecDeque<String>,
    queue_total: usize,
    queue_done: usize,
    current: Option<String>,
    finished: bool,
    error: Option<String>,
    no_rebuild: bool,
    selected_names: Vec<String>,
}

struct Rebuilding {
    stream: runner::Stream,
    log: VecDeque<String>,
    finished: bool,
    status: Option<ExitStatus>,
    cmd_label: String,
    selected_names: Vec<String>,
}

struct Done {
    success: bool,
    title: String,
    body: Vec<String>,
    log_tail: VecDeque<String>,
}

pub fn run(cfg: Config) -> Result<()> {
    let backup_lock = std::fs::read_to_string(cfg.flake_dir.join("flake.lock"))
        .context("read flake.lock")?;
    let mut term = setup_terminal()?;
    let res = run_inner(&mut term, cfg, backup_lock);
    teardown_terminal(&mut term)?;
    let msg = res?;
    if let Some(m) = msg {
        println!("{m}");
    }
    Ok(())
}

fn setup_terminal() -> Result<Terminal<CrosstermBackend<io::Stdout>>> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    Ok(Terminal::new(backend)?)
}

fn teardown_terminal(term: &mut Terminal<CrosstermBackend<io::Stdout>>) -> Result<()> {
    disable_raw_mode()?;
    execute!(term.backend_mut(), LeaveAlternateScreen)?;
    term.show_cursor()?;
    Ok(())
}

fn run_inner(
    term: &mut Terminal<CrosstermBackend<io::Stdout>>,
    cfg: Config,
    backup_lock: String,
) -> Result<Option<String>> {
    let mut app = App {
        phase: Phase::Updating(start_update(&cfg.flake_dir)?),
        cfg,
        started: Instant::now(),
        backup_lock,
        exit_message: None,
    };

    loop {
        term.draw(|f| draw(f, &app))?;
        if poll_events(&mut app)? {
            break;
        }
        if app.exit_message.is_some() {
            break;
        }
        thread::sleep(Duration::from_millis(80));
    }
    Ok(app.exit_message)
}

fn start_update(flake_dir: &std::path::Path) -> Result<Updating> {
    let mut cmd = Command::new("nix");
    cmd.args(["flake", "update"]).current_dir(flake_dir);
    let stream = runner::spawn(cmd).context("spawn nix flake update")?;
    Ok(Updating {
        stream,
        log: VecDeque::with_capacity(LOG_TAIL),
        finished: false,
        error: None,
    })
}

fn poll_events(app: &mut App) -> Result<bool> {
    drain_phase(app)?;

    if event::poll(Duration::from_millis(0))? {
        if let event::Event::Key(k) = event::read()? {
            if k.kind != KeyEventKind::Press {
                return Ok(false);
            }
            let handled = handle_key(app, k)?;
            if !handled && is_global_quit(&k) {
                return Ok(true);
            }
        }
    }
    Ok(false)
}

fn is_global_quit(k: &KeyEvent) -> bool {
    matches!(k.code, KeyCode::Char('q') | KeyCode::Esc)
        || (k.code == KeyCode::Char('c') && k.modifiers.contains(KeyModifiers::CONTROL))
}

fn drain_phase(app: &mut App) -> Result<()> {
    match &mut app.phase {
        Phase::Updating(u) => {
            while let Ok(ev) = u.stream.rx.try_recv() {
                match ev {
                    Event::Line(l) => push_line(&mut u.log, l.text()),
                    Event::Done(Ok(status)) => {
                        u.finished = true;
                        if !status.success() {
                            u.error = Some(format!("nix flake update exit: {status}"));
                        }
                    }
                    Event::Done(Err(e)) => {
                        u.finished = true;
                        u.error = Some(format!("nix flake update io: {e}"));
                    }
                }
            }
            if u.finished {
                transition_after_update(app)?;
            }
        }
        Phase::Applying(a) => {
            while let Ok(ev) = a.rx.try_recv() {
                match ev {
                    Event::Line(l) => {
                        let txt = l.text();
                        push_line(&mut a.log, txt);
                        if let Some(name) = txt.strip_prefix("[snowup] applying ") {
                            a.current = Some(name.to_string());
                        } else if txt.starts_with("[snowup] done ") {
                            a.current = None;
                            a.queue_done += 1;
                        } else if let Some(rest) = txt.strip_prefix("[snowup] error ") {
                            a.error = Some(rest.to_string());
                        }
                    }
                    Event::Done(Ok(status)) => {
                        a.finished = true;
                        if !status.success() && a.error.is_none() {
                            a.error = Some(format!("apply exit: {status}"));
                        }
                    }
                    Event::Done(Err(e)) => {
                        a.finished = true;
                        a.error = Some(format!("apply io: {e}"));
                    }
                }
            }
            if a.finished {
                transition_after_apply(app)?;
            }
        }
        Phase::Rebuilding(r) => {
            while let Ok(ev) = r.stream.rx.try_recv() {
                match ev {
                    Event::Line(l) => push_line(&mut r.log, l.text()),
                    Event::Done(Ok(status)) => {
                        r.finished = true;
                        r.status = Some(status);
                    }
                    Event::Done(Err(e)) => {
                        r.finished = true;
                        push_line(&mut r.log, &format!("[io] {e}"));
                    }
                }
            }
            if r.finished {
                transition_after_rebuild(app);
            }
        }
        _ => {}
    }
    Ok(())
}

fn transition_after_update(app: &mut App) -> Result<()> {
    let Phase::Updating(u) = std::mem::replace(
        &mut app.phase,
        Phase::Done(Done {
            success: false,
            title: String::new(),
            body: vec![],
            log_tail: VecDeque::new(),
        }),
    ) else {
        unreachable!()
    };
    if let Some(err) = u.error {
        app.phase = Phase::Done(Done {
            success: false,
            title: "flake update failed".into(),
            body: vec![err],
            log_tail: u.log,
        });
        return Ok(());
    }
    let new_lock_str = std::fs::read_to_string(app.cfg.flake_dir.join("flake.lock"))?;
    let old = flake::parse(&app.backup_lock)?;
    let new = flake::parse(&new_lock_str)?;
    let deltas = flake::diff(&old, &new);
    if deltas.is_empty() {
        app.exit_message = Some("flake.lock already current — no inputs changed.".into());
        return Ok(());
    }
    let selected = vec![true; deltas.len()];
    app.phase = Phase::Review(Review {
        deltas,
        selected,
        cursor: 0,
        diff: None,
    });
    Ok(())
}

fn transition_after_apply(app: &mut App) -> Result<()> {
    let Phase::Applying(a) = std::mem::replace(
        &mut app.phase,
        Phase::Done(Done {
            success: false,
            title: String::new(),
            body: vec![],
            log_tail: VecDeque::new(),
        }),
    ) else {
        unreachable!()
    };
    if let Some(err) = a.error {
        app.phase = Phase::Done(Done {
            success: false,
            title: "apply failed".into(),
            body: vec![err],
            log_tail: a.log,
        });
        return Ok(());
    }
    if a.no_rebuild {
        let mut body = vec![format!("updated {} input(s).", a.selected_names.len())];
        body.extend(a.selected_names.iter().map(|n| format!("  - {n}")));
        body.push(String::new());
        body.push("--no-rebuild set. press q to exit.".into());
        app.phase = Phase::Done(Done {
            success: true,
            title: "lock updated".into(),
            body,
            log_tail: a.log,
        });
        return Ok(());
    }
    app.phase = Phase::Rebuilding(start_rebuild(&app.cfg, a.selected_names)?);
    Ok(())
}

fn start_rebuild(cfg: &Config, selected_names: Vec<String>) -> Result<Rebuilding> {
    let cmd = host::rebuild_command(cfg.os, &cfg.host, &cfg.flake_dir)?;
    let cmd_label = format!(
        "{} {} (cwd: {})",
        cmd.get_program().to_string_lossy(),
        cmd.get_args()
            .map(|a| a.to_string_lossy().into_owned())
            .collect::<Vec<_>>()
            .join(" "),
        cfg.flake_dir.display()
    );
    let stream = runner::spawn(cmd).context("spawn rebuild")?;
    Ok(Rebuilding {
        stream,
        log: VecDeque::with_capacity(LOG_TAIL),
        finished: false,
        status: None,
        cmd_label,
        selected_names,
    })
}

fn transition_after_rebuild(app: &mut App) {
    let Phase::Rebuilding(r) = std::mem::replace(
        &mut app.phase,
        Phase::Done(Done {
            success: false,
            title: String::new(),
            body: vec![],
            log_tail: VecDeque::new(),
        }),
    ) else {
        unreachable!()
    };
    let success = r.status.map(|s| s.success()).unwrap_or(false);
    let suspects = if success {
        vec![]
    } else {
        scan_suspects(&r.log, &r.selected_names)
    };
    let title = if success {
        "rebuild succeeded".into()
    } else {
        format!(
            "rebuild failed ({})",
            r.status
                .as_ref()
                .map(|s| s.to_string())
                .unwrap_or_else(|| "no status".into())
        )
    };
    let mut body = vec![r.cmd_label.clone()];
    if !success && !suspects.is_empty() {
        body.push(String::new());
        body.push("suspect inputs (mentioned in error lines):".into());
        for s in &suspects {
            body.push(format!("  - {s}"));
        }
    }
    body.push(String::new());
    body.push("press q to exit.".into());
    app.phase = Phase::Done(Done {
        success,
        title,
        body,
        log_tail: r.log,
    });
}

fn scan_suspects(log: &VecDeque<String>, names: &[String]) -> Vec<String> {
    use std::collections::HashMap;
    let mut hits: HashMap<&str, usize> = HashMap::new();
    for line in log {
        if !line.contains("error") {
            continue;
        }
        let lc = line.to_lowercase();
        for n in names {
            if lc.contains(&n.to_lowercase()) {
                *hits.entry(n.as_str()).or_default() += 1;
            }
        }
    }
    let mut v: Vec<(&str, usize)> = hits.into_iter().collect();
    v.sort_by(|a, b| b.1.cmp(&a.1));
    v.into_iter().map(|(n, _)| n.to_string()).collect()
}

enum ReviewAction {
    NotConsumed,
    ConsumedNoop,
    Apply(Vec<String>),
}

fn handle_key(app: &mut App, k: KeyEvent) -> Result<bool> {
    let action = match &mut app.phase {
        Phase::Review(r) => review_key(r, k),
        _ => ReviewAction::NotConsumed,
    };
    match action {
        ReviewAction::NotConsumed => Ok(false),
        ReviewAction::ConsumedNoop => Ok(true),
        ReviewAction::Apply(names) => {
            app.phase = Phase::Applying(start_apply(
                app.cfg.flake_dir.clone(),
                app.backup_lock.clone(),
                names,
                app.cfg.no_rebuild,
            )?);
            Ok(true)
        }
    }
}

fn review_key(r: &mut Review, k: KeyEvent) -> ReviewAction {
    if r.diff.is_some() {
        if matches!(
            k.code,
            KeyCode::Esc | KeyCode::Char('q') | KeyCode::Char('d') | KeyCode::Enter
        ) {
            r.diff = None;
            return ReviewAction::ConsumedNoop;
        }
        return ReviewAction::ConsumedNoop;
    }
    match k.code {
        KeyCode::Char('j') | KeyCode::Down => {
            if r.cursor + 1 < r.deltas.len() {
                r.cursor += 1;
            }
            ReviewAction::ConsumedNoop
        }
        KeyCode::Char('k') | KeyCode::Up => {
            if r.cursor > 0 {
                r.cursor -= 1;
            }
            ReviewAction::ConsumedNoop
        }
        KeyCode::Char(' ') => {
            if !r.selected.is_empty() {
                r.selected[r.cursor] = !r.selected[r.cursor];
            }
            ReviewAction::ConsumedNoop
        }
        KeyCode::Char('a') => {
            r.selected.iter_mut().for_each(|b| *b = true);
            ReviewAction::ConsumedNoop
        }
        KeyCode::Char('n') => {
            r.selected.iter_mut().for_each(|b| *b = false);
            ReviewAction::ConsumedNoop
        }
        KeyCode::Char('d') => {
            r.diff = Some(r.cursor);
            ReviewAction::ConsumedNoop
        }
        KeyCode::Enter => {
            let names: Vec<String> = r
                .deltas
                .iter()
                .zip(r.selected.iter())
                .filter_map(|(d, sel)| if *sel { Some(d.name.clone()) } else { None })
                .collect();
            ReviewAction::Apply(names)
        }
        _ => ReviewAction::NotConsumed,
    }
}

fn start_apply(
    flake_dir: PathBuf,
    backup_lock: String,
    selected_names: Vec<String>,
    no_rebuild: bool,
) -> Result<Applying> {
    let (tx, rx) = mpsc::channel::<Event>();
    let total = selected_names.len();
    let names_for_thread = selected_names.clone();
    thread::spawn(move || apply_thread(flake_dir, backup_lock, names_for_thread, tx));
    Ok(Applying {
        rx,
        log: VecDeque::with_capacity(LOG_TAIL),
        queue_total: total,
        queue_done: 0,
        current: None,
        finished: false,
        error: None,
        no_rebuild,
        selected_names,
    })
}

fn apply_thread(
    flake_dir: PathBuf,
    backup_lock: String,
    selected_names: Vec<String>,
    tx: Sender<Event>,
) {
    let restore = |tx: &Sender<Event>| -> std::io::Result<()> {
        std::fs::write(flake_dir.join("flake.lock"), &backup_lock)?;
        let _ = tx.send(Event::Line(Line::Stdout("[snowup] restored backup lock".into())));
        Ok(())
    };
    if let Err(e) = restore(&tx) {
        let _ = tx.send(Event::Line(Line::Stderr(format!(
            "[snowup] error restore: {e}"
        ))));
        let _ = tx.send(Event::Done(Err(e)));
        return;
    }

    let mut overall_ok = true;
    for name in &selected_names {
        let _ = tx.send(Event::Line(Line::Stdout(format!("[snowup] applying {name}"))));
        let mut cmd = Command::new("nix");
        cmd.args(["flake", "update", name]).current_dir(&flake_dir);
        match runner::run_sync(cmd, &tx) {
            Ok(status) => {
                if !status.success() {
                    overall_ok = false;
                    let _ = tx.send(Event::Line(Line::Stderr(format!(
                        "[snowup] error {name}: exit {status}"
                    ))));
                    break;
                }
                let _ = tx.send(Event::Line(Line::Stdout(format!("[snowup] done {name}"))));
            }
            Err(e) => {
                overall_ok = false;
                let _ = tx.send(Event::Line(Line::Stderr(format!(
                    "[snowup] error {name}: {e}"
                ))));
                break;
            }
        }
    }

    let status = if overall_ok {
        std::process::Command::new("true").status()
    } else {
        std::process::Command::new("false").status()
    };
    let _ = tx.send(Event::Done(status));
}

fn push_line(buf: &mut VecDeque<String>, s: &str) {
    if buf.len() >= LOG_TAIL {
        buf.pop_front();
    }
    buf.push_back(strip_ansi(s));
}

fn strip_ansi(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    let mut chars = s.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\x1b' {
            if chars.peek() == Some(&'[') {
                chars.next();
                while let Some(&nc) = chars.peek() {
                    chars.next();
                    if nc.is_ascii_alphabetic() {
                        break;
                    }
                }
            }
            continue;
        }
        out.push(c);
    }
    out
}

fn draw(f: &mut Frame, app: &App) {
    let area = f.area();
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(3), Constraint::Min(1), Constraint::Length(2)])
        .split(area);

    draw_header(f, chunks[0], app);
    match &app.phase {
        Phase::Updating(u) => draw_updating(f, chunks[1], app, u),
        Phase::Review(r) => draw_review(f, chunks[1], r),
        Phase::Applying(a) => draw_applying(f, chunks[1], a),
        Phase::Rebuilding(r) => draw_rebuilding(f, chunks[1], r),
        Phase::Done(d) => draw_done(f, chunks[1], d),
    }
    draw_footer(f, chunks[2], app);

    if let Phase::Review(r) = &app.phase {
        if let Some(idx) = r.diff {
            draw_diff_popup(f, area, &r.deltas[idx]);
        }
    }
}

fn draw_header(f: &mut Frame, area: Rect, app: &App) {
    let title = format!(
        "snowup @ {} ({}) — {}",
        app.cfg.host,
        app.cfg.os.label(),
        app.cfg.flake_dir.display()
    );
    let elapsed = app.started.elapsed().as_secs();
    let right = format!("elapsed {}s", elapsed);
    let line = TLine::from(vec![
        Span::styled(title, Style::new().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
        Span::raw("  "),
        Span::styled(right, Style::new().fg(Color::DarkGray)),
    ]);
    let p = Paragraph::new(line)
        .block(Block::default().borders(Borders::ALL).title(" snowup "));
    f.render_widget(p, area);
}

fn draw_footer(f: &mut Frame, area: Rect, app: &App) {
    let hint = match &app.phase {
        Phase::Updating(_) => "running nix flake update… (q to cancel)",
        Phase::Review(_) => "j/k move  space toggle  a all  n none  d diff  enter apply  q quit",
        Phase::Applying(_) => "applying lock updates…",
        Phase::Rebuilding(_) => "rebuilding host… (q to detach, build continues)",
        Phase::Done(_) => "q to quit",
    };
    let p = Paragraph::new(hint)
        .alignment(Alignment::Left)
        .style(Style::new().fg(Color::DarkGray));
    f.render_widget(p, area);
}

fn draw_updating(f: &mut Frame, area: Rect, app: &App, u: &Updating) {
    let layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(3), Constraint::Min(1)])
        .split(area);

    let frame_idx = (app.started.elapsed().as_millis() / 100) as usize;
    let spin = SPIN[frame_idx % SPIN.len()];
    let head = format!("{spin}  nix flake update");
    let p = Paragraph::new(head).block(
        Block::default()
            .borders(Borders::ALL)
            .title(" step 1/3: update lock "),
    );
    f.render_widget(p, layout[0]);

    let lines: Vec<TLine> = u.log.iter().rev().take(layout[1].height as usize).rev()
        .map(|s| TLine::from(s.clone())).collect();
    let log = Paragraph::new(lines)
        .block(Block::default().borders(Borders::ALL).title(" log "))
        .wrap(Wrap { trim: false });
    f.render_widget(log, layout[1]);
}

fn draw_review(f: &mut Frame, area: Rect, r: &Review) {
    let header = Row::new(vec![
        Cell::from(""),
        Cell::from(""),
        Cell::from("input").style(Style::new().add_modifier(Modifier::BOLD)),
        Cell::from("old").style(Style::new().add_modifier(Modifier::BOLD)),
        Cell::from("→ new").style(Style::new().add_modifier(Modifier::BOLD)),
        Cell::from("age").style(Style::new().add_modifier(Modifier::BOLD)),
        Cell::from("when").style(Style::new().add_modifier(Modifier::BOLD)),
    ]);
    let rows: Vec<Row> = r
        .deltas
        .iter()
        .enumerate()
        .map(|(i, d)| {
            let arrow = if i == r.cursor { "▶" } else { " " };
            let mark = if r.selected[i] { "[x]" } else { "[ ]" };
            let age = d
                .age_days()
                .map(|n| format!("+{n}d"))
                .unwrap_or_else(|| "—".into());
            let when = d
                .new_modified
                .and_then(|t| DateTime::<Utc>::from_timestamp(t, 0))
                .map(|dt| dt.format("%Y-%m-%d").to_string())
                .unwrap_or_else(|| "—".into());
            let mut style = Style::default();
            if i == r.cursor {
                style = style.bg(Color::Blue).fg(Color::White).add_modifier(Modifier::BOLD);
            }
            if !r.selected[i] {
                style = style.add_modifier(Modifier::DIM | Modifier::CROSSED_OUT);
            }
            Row::new(vec![
                Cell::from(arrow),
                Cell::from(mark),
                Cell::from(d.name.clone()),
                Cell::from(d.old_short()),
                Cell::from(d.new_short()),
                Cell::from(age),
                Cell::from(when),
            ])
            .style(style)
        })
        .collect();
    let widths = [
        Constraint::Length(2),
        Constraint::Length(3),
        Constraint::Length(28),
        Constraint::Length(10),
        Constraint::Length(10),
        Constraint::Length(8),
        Constraint::Length(12),
    ];
    let table = Table::new(rows, widths).header(header).block(
        Block::default()
            .borders(Borders::ALL)
            .title(format!(
                " step 2/3: review ({} of {} selected) ",
                r.selected.iter().filter(|b| **b).count(),
                r.deltas.len()
            )),
    );
    f.render_widget(table, area);
}

fn draw_applying(f: &mut Frame, area: Rect, a: &Applying) {
    let layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(4), Constraint::Min(1)])
        .split(area);

    let ratio = if a.queue_total == 0 {
        1.0
    } else {
        a.queue_done as f64 / a.queue_total as f64
    };
    let label = match &a.current {
        Some(n) => format!("{}/{} — {n}", a.queue_done, a.queue_total),
        None => format!("{}/{}", a.queue_done, a.queue_total),
    };
    let gauge = Gauge::default()
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title(" applying updates "),
        )
        .ratio(ratio.clamp(0.0, 1.0))
        .label(label)
        .gauge_style(Style::new().fg(Color::Green));
    f.render_widget(gauge, layout[0]);

    let lines: Vec<TLine> = a.log.iter().rev().take(layout[1].height as usize).rev()
        .map(|s| TLine::from(s.clone())).collect();
    let log = Paragraph::new(lines)
        .block(Block::default().borders(Borders::ALL).title(" log "))
        .wrap(Wrap { trim: false });
    f.render_widget(log, layout[1]);
}

fn draw_rebuilding(f: &mut Frame, area: Rect, r: &Rebuilding) {
    let layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(3), Constraint::Min(1)])
        .split(area);

    let head = Paragraph::new(r.cmd_label.clone()).block(
        Block::default()
            .borders(Borders::ALL)
            .title(" step 3/3: rebuild "),
    );
    f.render_widget(head, layout[0]);

    let lines: Vec<TLine> = r
        .log
        .iter()
        .rev()
        .take(layout[1].height as usize)
        .rev()
        .map(|s| {
            let style = if s.contains("error") {
                Style::new().fg(Color::Red)
            } else if s.contains("warning") {
                Style::new().fg(Color::Yellow)
            } else {
                Style::default()
            };
            TLine::from(Span::styled(s.clone(), style))
        })
        .collect();
    let log = Paragraph::new(lines)
        .block(Block::default().borders(Borders::ALL).title(" build log "))
        .wrap(Wrap { trim: false });
    f.render_widget(log, layout[1]);
}

fn draw_done(f: &mut Frame, area: Rect, d: &Done) {
    let layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(8), Constraint::Min(1)])
        .split(area);
    let (color, mark) = if d.success {
        (Color::Green, "✓")
    } else {
        (Color::Red, "✗")
    };
    let mut lines: Vec<TLine> = vec![TLine::from(Span::styled(
        format!("{mark} {}", d.title),
        Style::new().fg(color).add_modifier(Modifier::BOLD),
    ))];
    for l in &d.body {
        lines.push(TLine::from(l.clone()));
    }
    let header = Paragraph::new(lines).block(
        Block::default()
            .borders(Borders::ALL)
            .title(" result ")
            .padding(Padding::new(1, 1, 0, 0)),
    );
    f.render_widget(header, layout[0]);

    let log_lines: Vec<TLine> = d
        .log_tail
        .iter()
        .rev()
        .take(layout[1].height as usize)
        .rev()
        .map(|s| TLine::from(s.clone()))
        .collect();
    let log = Paragraph::new(log_lines)
        .block(Block::default().borders(Borders::ALL).title(" log tail "))
        .wrap(Wrap { trim: false });
    f.render_widget(log, layout[1]);
}

fn draw_diff_popup(f: &mut Frame, area: Rect, d: &Delta) {
    let w = area.width.saturating_sub(8).min(90);
    let h = area.height.saturating_sub(6).min(14);
    let popup = centered_rect(w, h, area);
    f.render_widget(Clear, popup);

    let mut lines: Vec<TLine> = vec![
        TLine::from(Span::styled(
            format!("input: {}", d.name),
            Style::new().fg(Color::Cyan).add_modifier(Modifier::BOLD),
        )),
        TLine::from(format!("old rev: {}", d.old_rev.clone().unwrap_or_else(|| "—".into()))),
        TLine::from(format!("new rev: {}", d.new_rev.clone().unwrap_or_else(|| "—".into()))),
    ];
    if let Some(n) = d.age_days() {
        lines.push(TLine::from(format!("upstream advanced {n}d")));
    }
    if let Some(url) = d.compare_url() {
        lines.push(TLine::from(""));
        lines.push(TLine::from(Span::styled(
            format!("compare: {url}"),
            Style::new().fg(Color::Blue).add_modifier(Modifier::UNDERLINED),
        )));
    } else if let Some(url) = d.commit_url() {
        lines.push(TLine::from(""));
        lines.push(TLine::from(Span::styled(
            format!("commit: {url}"),
            Style::new().fg(Color::Blue).add_modifier(Modifier::UNDERLINED),
        )));
    }
    lines.push(TLine::from(""));
    lines.push(TLine::from(Span::styled(
        "esc/d/enter to close",
        Style::new().fg(Color::DarkGray),
    )));
    let p = Paragraph::new(lines)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title(" diff ")
                .padding(Padding::new(1, 1, 0, 0)),
        )
        .wrap(Wrap { trim: false });
    f.render_widget(p, popup);
}

fn centered_rect(w: u16, h: u16, area: Rect) -> Rect {
    let x = area.x + (area.width.saturating_sub(w)) / 2;
    let y = area.y + (area.height.saturating_sub(h)) / 2;
    Rect::new(x, y, w.min(area.width), h.min(area.height))
}
