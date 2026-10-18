//! Single-file launcher for JANUS.
//!
//! The release ZIP is appended to this executable, followed by an 8-byte magic
//! and a little-endian u64 payload length. On first launch the ZIP is extracted
//! to `%LOCALAPPDATA%\JANUS\<payload-hash>`; later launches reuse that directory.
//! Extraction is versioned by the payload hash, so upgrading never mixes files.

#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::fs::{self, File};
use std::io::{self, Cursor, Read, Seek, SeekFrom, Write};
use std::path::{Path, PathBuf};
use std::process::Command;

const FOOTER_MAGIC: &[u8; 8] = b"JANUSPAK";
const FOOTER_BYTES: u64 = 16;

fn main() {
    if let Err(error) = run() {
        show_error(&error);
        std::process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let executable = std::env::current_exe().map_err(|error| format!("无法定位启动器：{error}"))?;
    let payload = read_payload(&executable)?;
    let destination = extract_directory(&payload);
    let marker = destination.join(".janus-complete");

    if !marker.exists() {
        if destination.exists() {
            fs::remove_dir_all(&destination).map_err(|error| format!("无法清理旧版本：{error}"))?;
        }
        fs::create_dir_all(&destination).map_err(|error| format!("无法创建解压目录：{error}"))?;
        extract_zip(&payload, &destination)?;
        File::create(&marker)
            .and_then(|mut file| file.write_all(b"ok"))
            .map_err(|error| format!("无法写入完成标记：{error}"))?;
    }

    let application = destination.join("JANUS.exe");
    if !application.exists() {
        return Err("解压后的程序缺少 JANUS.exe。".to_owned());
    }

    Command::new(&application)
        .current_dir(&destination)
        .args(std::env::args_os().skip(1))
        .spawn()
        .map_err(|error| format!("无法启动 JANUS：{error}"))?;
    Ok(())
}

fn read_payload(executable: &Path) -> Result<Vec<u8>, String> {
    let mut file = File::open(executable).map_err(|error| format!("无法读取启动器：{error}"))?;
    let length = file
        .metadata()
        .map_err(|error| format!("无法读取启动器大小：{error}"))?
        .len();
    if length < FOOTER_BYTES {
        return Err("启动器缺少内嵌数据。".to_owned());
    }

    file.seek(SeekFrom::End(-(FOOTER_BYTES as i64)))
        .map_err(|error| error.to_string())?;
    let mut footer = [0_u8; FOOTER_BYTES as usize];
    file.read_exact(&mut footer)
        .map_err(|error| error.to_string())?;
    if &footer[..8] != FOOTER_MAGIC {
        return Err("这不是有效的 JANUS 单文件包。".to_owned());
    }

    let payload_length = u64::from_le_bytes(footer[8..16].try_into().unwrap());
    let offset = length
        .checked_sub(FOOTER_BYTES + payload_length)
        .ok_or_else(|| "单文件包长度无效。".to_owned())?;
    file.seek(SeekFrom::Start(offset))
        .map_err(|error| error.to_string())?;
    let mut payload = vec![0_u8; payload_length as usize];
    file.read_exact(&mut payload)
        .map_err(|error| error.to_string())?;
    Ok(payload)
}

fn extract_directory(payload: &[u8]) -> PathBuf {
    let root = std::env::var_os("LOCALAPPDATA")
        .map(PathBuf::from)
        .unwrap_or_else(std::env::temp_dir);
    let mut hash = 0xcbf2_9ce4_8422_2325_u64;
    for byte in payload {
        hash ^= u64::from(*byte);
        hash = hash.wrapping_mul(0x0000_0100_0000_01b3);
    }
    root.join("JANUS").join(format!("{hash:016x}"))
}

fn extract_zip(payload: &[u8], destination: &Path) -> Result<(), String> {
    let mut archive = zip::ZipArchive::new(Cursor::new(payload))
        .map_err(|error| format!("无法读取内嵌压缩包：{error}"))?;
    for index in 0..archive.len() {
        let mut entry = archive.by_index(index).map_err(|error| error.to_string())?;
        let name = match entry.enclosed_name() {
            Some(name) => name.to_string_lossy().replace('\\', "/"),
            None => continue,
        };
        let target = destination.join(name);
        if entry.is_dir() {
            fs::create_dir_all(&target).map_err(|error| error.to_string())?;
            continue;
        }
        if let Some(parent) = target.parent() {
            fs::create_dir_all(parent).map_err(|error| error.to_string())?;
        }
        let mut output = File::create(&target).map_err(|error| error.to_string())?;
        io::copy(&mut entry, &mut output).map_err(|error| error.to_string())?;
    }
    Ok(())
}

fn show_error(message: &str) {
    #[cfg(windows)]
    unsafe {
        use windows_sys::Win32::UI::WindowsAndMessaging::{MessageBoxW, MB_ICONERROR, MB_OK};
        let text: Vec<u16> = message.encode_utf16().chain(std::iter::once(0)).collect();
        let title: Vec<u16> = "JANUS".encode_utf16().chain(std::iter::once(0)).collect();
        MessageBoxW(0, text.as_ptr(), title.as_ptr(), MB_OK | MB_ICONERROR);
    }
    #[cfg(not(windows))]
    eprintln!("{message}");
}
