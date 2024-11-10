const std = @import("std");
const lexer = @import("./lexer.zig");
const token = @import("./token.zig");

pub fn main() !void {
    // repl
    const prompt = ">> ";
    var inputBuf: [1024]u8 = [_]u8{'0'} ** 1024;
    while (true) {
        // print the prompt
        try std.io.getStdOut().writeAll(prompt);
        // read from the stdin
        const input = try std.io.getStdIn().reader().readUntilDelimiter(&inputBuf, '\n');
        if (std.mem.eql(u8, ".exit", input)) {
            break;
        }
        var lex = try lexer.Lexer.init(input);
        // print the tokens
        var tok = lex.next_token();
        while (tok.type_ != token.TokenType.EOF) {
            tok.to_string();
            tok = lex.next_token();
        }
    }
}
