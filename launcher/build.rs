use std::env;

fn main() {
    if env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }
    let mut resource = winres::WindowsResource::new();
    resource.set_icon("../windows/runner/resources/app_icon.ico");
    resource.set("CompanyName", "io.github.tylenoler");
    resource.set("FileDescription", "JANUS Portable Launcher");
    resource.set("FileVersion", "2.1.0.0");
    resource.set("InternalName", "JANUS Portable");
    resource.set("LegalCopyright", "Copyright (C) 2026 Tylenoler");
    resource.set("OriginalFilename", "JANUS-portable.exe");
    resource.set("ProductName", "JANUS");
    resource.set("ProductVersion", "2.1.0.0");
    resource
        .compile()
        .expect("failed to compile the JANUS launcher resources");
}
