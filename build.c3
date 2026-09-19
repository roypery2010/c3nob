module build;

import c3nob;
import std::io;

fn void print_usage(String program_name)
{
    io::printfn("Usage: c3c compile-run %s [configure|debug|release|clean]", program_name);
}

fn void main(String[] args)
{
    if (args.len < 2)
    {
        print_usage(args.len > 0 ? args[0] : "build.c3");
        return;
    }

    String action = args[1];

    // 1. Configure Action (Scaffolds build.conf, README.md, LICENSE.md, and .gitignore)
    if (action == "configure")
    {
        io::printn("[INFO] Scaffolding project files...");

        // build.conf
        String conf_content = "# build.conf configuration\n"
                              "name = main\n"
                              "target = posix\n"
                              "hotreload = false\n"
                              "sources = main.c3\n";
        if (!c3nob::c3nob_write_entire_file("build.conf", conf_content))
        {
            io::printn("[ERROR] Failed to write build.conf!");
            return;
        }

        // README.md
        String readme_content = "# c3nob 🛠️\n\n"
                                "`c3nob` is a lightweight, C3-native, dependency-free build system script designed to provide a clean, programmatic alternative for managing C3 projects.\n\n"
                                "## Getting Started\n\n"
                                "- Configure: `c3c compile-run build.c3 c3nob.c3 configure`\n"
                                "- Debug Build & Run: `c3c compile-run build.c3 c3nob.c3 debug`\n"
                                "- Release Build & Run: `c3c compile-run build.c3 c3nob.c3 release`\n"
                                "- Clean: `c3c compile-run build.c3 c3nob.c3 clean`\n";
        if (!c3nob::c3nob_write_entire_file("README.md", readme_content))
        {
            io::printn("[ERROR] Failed to write README.md!");
            return;
        }

        // LICENSE.md
        String license_content = "MIT License\n\n"
                                 "Copyright (c) 2026\n\n"
                                 "Permission is hereby granted, free of charge, to any person obtaining a copy\n"
                                 "of this software and associated documentation files (the \"Software\"), to deal\n"
                                 "in the Software without restriction, including without limitation the rights\n"
                                 "to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n"
                                 "copies of the Software, and to permit persons to whom the Software is\n"
                                 "furnished to do so, subject to the following conditions:\n\n"
                                 "The above copyright notice and this permission notice shall be included in all\n"
                                 "copies or substantial portions of the Software.\n\n"
                                 "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n"
                                 "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n"
                                 "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n"
                                 "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n"
                                 "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n"
                                 "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n"
                                 "SOFTWARE.\n";
        if (!c3nob::c3nob_write_entire_file("LICENSE.md", license_content))
        {
            io::printn("[ERROR] Failed to write LICENSE.md!");
            return;
        }

        // .gitignore
        String gitignore_content = "/main\n"
                                   "/main.exe\n"
                                   "build.conf\n"
                                   "/.c3/\n"
                                   "*.o\n";
        if (!c3nob::c3nob_write_entire_file(".gitignore", gitignore_content))
        {
            io::printn("[ERROR] Failed to write .gitignore!");
            return;
        }

        io::printn("[INFO] All project boilerplate files generated successfully!");
        return;
    }

    // 2. Clean Action
    if (action == "clean")
    {
        io::printn("[INFO] Cleaning build artifacts...");
        return;
    }

    // 3. Build Actions (debug or release)
    bool is_release = (action == "release");
    
    C3Nob_Cmd cmd = {};
    defer cmd.free();

    $if env::WIN32:
        cmd.@append("c3c");
    $else
        cmd.@append("../c3/c3c");
    $endif

    cmd.@append("compile");
    cmd.@append("main.c3");

    if (is_release)
    {
        io::printn("[INFO] Building in RELEASE mode (-O3)");
        cmd.@append("-O3");
    }
    else
    {
        io::printn("[INFO] Building in DEBUG mode (-g)");
        cmd.@append("-g");
    }

    cmd.@append("-o");

    C3Nob_String_Builder out_name = {};
    defer out_name.free();
    
    out_name.append_cstr("main");
    out_name.append_cstr(c3nob::c3nob_target_ext());
    out_name.append_null();

    cmd.@append((ZString)out_name.items);

    if (!cmd.run())
    {
        io::printn("[ERROR] Build failed!");
        return;
    }

    io::printn("[INFO] Build successful! Running executable...");

    // 4. Run the compiled executable automatically
    C3Nob_Cmd run_cmd = {};
    defer run_cmd.free();

    C3Nob_String_Builder run_path = {};
    defer run_path.free();

    $if env::WIN32:
        run_path.append_cstr("main");
    $else
        run_path.append_cstr("./main");
    $endif

    run_path.append_cstr(c3nob::c3nob_target_ext());
    run_path.append_null();

    run_cmd.@append((ZString)run_path.items);

    if (!run_cmd.run())
    {
        io::printn("[ERROR] Failed to execute binary!");
        return;
    }
}