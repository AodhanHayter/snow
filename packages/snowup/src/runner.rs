use anyhow::Result;
use std::io::{BufRead, BufReader};
use std::process::{Command, ExitStatus, Stdio};
use std::sync::mpsc::{self, Receiver, Sender};
use std::thread;

#[derive(Debug, Clone)]
pub enum Line {
    Stdout(String),
    Stderr(String),
}

impl Line {
    pub fn text(&self) -> &str {
        match self {
            Line::Stdout(s) | Line::Stderr(s) => s,
        }
    }
}

#[derive(Debug)]
pub enum Event {
    Line(Line),
    Done(std::io::Result<ExitStatus>),
}

pub struct Stream {
    pub rx: Receiver<Event>,
}

pub fn spawn(mut cmd: Command) -> Result<Stream> {
    cmd.stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .stdin(Stdio::null());
    let mut child = cmd.spawn()?;
    let stdout = child.stdout.take().unwrap();
    let stderr = child.stderr.take().unwrap();
    let (tx, rx) = mpsc::channel::<Event>();
    let tx_out = tx.clone();
    thread::spawn(move || {
        for line in BufReader::new(stdout).lines().map_while(|r| r.ok()) {
            let _ = tx_out.send(Event::Line(Line::Stdout(line)));
        }
    });
    let tx_err = tx.clone();
    thread::spawn(move || {
        for line in BufReader::new(stderr).lines().map_while(|r| r.ok()) {
            let _ = tx_err.send(Event::Line(Line::Stderr(line)));
        }
    });
    thread::spawn(move || {
        let status = child.wait();
        let _ = tx.send(Event::Done(status));
    });
    Ok(Stream { rx })
}

pub fn run_sync(mut cmd: Command, tx: &Sender<Event>) -> std::io::Result<ExitStatus> {
    cmd.stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .stdin(Stdio::null());
    let mut child = cmd.spawn()?;
    let stdout = child.stdout.take().unwrap();
    let stderr = child.stderr.take().unwrap();
    let tx1 = tx.clone();
    let h1 = thread::spawn(move || {
        for line in BufReader::new(stdout).lines().map_while(|r| r.ok()) {
            let _ = tx1.send(Event::Line(Line::Stdout(line)));
        }
    });
    let tx2 = tx.clone();
    let h2 = thread::spawn(move || {
        for line in BufReader::new(stderr).lines().map_while(|r| r.ok()) {
            let _ = tx2.send(Event::Line(Line::Stderr(line)));
        }
    });
    let status = child.wait()?;
    let _ = h1.join();
    let _ = h2.join();
    Ok(status)
}
