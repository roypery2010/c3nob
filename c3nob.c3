module c3nob;

import std::io;
import std::core::mem;

extern fn int system(ZString command);

struct C3Nob_Cmd
{
    ZString* args;
    usz count;
    usz capacity;
}

struct C3Nob_String_Builder
{
    char* items;
    usz count;
    usz capacity;
}

// ==========================================
// C3Nob_Cmd Implementation
// ==========================================

macro void C3Nob_Cmd.@append(&self, #arg)
{
    if (self.count >= self.capacity)
    {
        self.capacity = self.capacity == 0 ? 16 : self.capacity * 2;
        self.args = mem::realloc((void*)self.args, (sz)(self.capacity * @sizeof(self.args[0])));
    }
    self.args[self.count++] = #arg;
}

fn void C3Nob_Cmd.render(&self, C3Nob_String_Builder* sb)
{
    for (usz i = 0; i < self.count; i++)
    {
        sb.append_cstr(self.args[i]);
        if (i + 1 < self.count)
        {
            sb.@append(' ');
        }
    }
}

fn bool C3Nob_Cmd.run(&self)
{
    if (self.count == 0)
    {
        io::printn("[INFO] Empty command, nothing to run.");
        return true;
    }

    C3Nob_String_Builder sb = {};
    defer sb.free();

    self.render(&sb);
    sb.append_null();

    io::printfn("[CMD] %s", (ZString)sb.items);
    int result = system((ZString)sb.items);
    
    return result == 0;
}

fn void C3Nob_Cmd.free(&self)
{
    if (self.args)
    {
        mem::free(self.args);
        self.args = null;
        self.count = 0;
        self.capacity = 0;
    }
}

// ==========================================
// C3Nob_String_Builder Implementation
// ==========================================

macro void C3Nob_String_Builder.@append(&self, char item)
{
    if (self.count >= self.capacity)
    {
        self.capacity = self.capacity == 0 ? 256 : self.capacity * 2;
        self.items = mem::realloc((void*)self.items, (sz)self.capacity);
    }
    self.items[self.count++] = item;
}

fn void C3Nob_String_Builder.append_cstr(&self, ZString cstr)
{
    if (!cstr) return;
    char* p = (char*)cstr;
    while (*p != '\0')
    {
        self.@append(*p);
        p++;
    }
}

fn void C3Nob_String_Builder.append_null(&self)
{
    self.@append('\0');
    if (self.count > 0) self.count--;
}

fn void C3Nob_String_Builder.free(&self)
{
    if (self.items)
    {
        mem::free(self.items);
        self.items = null;
        self.count = 0;
        self.capacity = 0;
    }
}

extern fn void* fopen(ZString filename, ZString mode);
extern fn int fprintf(void* stream, ZString format, ...);
extern fn int fclose(void* stream);

// Writes a C3 String slice to a file, creating or overwriting it.
fn bool c3nob_write_entire_file(ZString filename, String content)
{
    void* f = fopen(filename, "w");
    if (!f) return false;

    // Convert C3 String slice to a null-terminated ZString for C interop
    ZString zcontent = content.zstr_copy(mem);
    defer mem::free(zcontent);

    fprintf(f, "%s", zcontent);
    fclose(f);
    return true;
}

// ==========================================
// Platform Helper Functions (@feat)
// ==========================================

fn ZString nob_target_ext() @feat(WIN32)
{
    return ".exe";
}