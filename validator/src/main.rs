use std::fs;
use std::path::PathBuf;
use std::process;

fn main() {
    let args: Vec<String> = std::env::args().collect();

    if args.len() < 3 {
        eprintln!("Usage: vtr_findings_validator <schema.json> <finding.json> [...]");
        process::exit(1);
    }

    let schema_path = PathBuf::from(&args[1]);
    let finding_paths: Vec<PathBuf> = args[2..].iter().map(PathBuf::from).collect();

    let schema_str = match fs::read_to_string(&schema_path) {
        Ok(s) => s,
        Err(e) => { eprintln!("Error reading schema: {}", e); process::exit(1); }
    };

    let schema_json: serde_json::Value = match serde_json::from_str(&schema_str) {
        Ok(v) => v,
        Err(e) => { eprintln!("Error parsing schema: {}", e); process::exit(1); }
    };

    let compiled = match jsonschema::options().build(&schema_json) {
        Ok(v) => v,
        Err(e) => { eprintln!("Error compiling schema: {}", e); process::exit(1); }
    };

    let mut all_valid = true;

    for path in &finding_paths {
        let finding_str = match fs::read_to_string(path) {
            Ok(s) => s,
            Err(e) => {
                eprintln!("[FAIL] {}: cannot read — {}", path.display(), e);
                all_valid = false;
                continue;
            }
        };

        let finding_json: serde_json::Value = match serde_json::from_str(&finding_str) {
            Ok(v) => v,
            Err(e) => {
                eprintln!("[FAIL] {}: invalid JSON — {}", path.display(), e);
                all_valid = false;
                continue;
            }
        };

        let errors: Vec<_> = compiled.iter_errors(&finding_json).collect();

        if errors.is_empty() {
            println!("[OK]   {}", path.display());
        } else {
            eprintln!("[FAIL] {}: {} error(s)", path.display(), errors.len());
            for error in &errors {
                eprintln!("       - {}: {}", error.instance_path(), error);
            }
            all_valid = false;
        }
    }

    if all_valid {
        println!("\nAll findings valid.");
        process::exit(0);
    } else {
        eprintln!("\nValidation failed.");
        process::exit(1);
    }
}
