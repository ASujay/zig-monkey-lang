const std = @import("std");
const token = @import("./token.zig");

pub const Lexer = struct {
    input: []const u8,
    position: u64,
    read_position: u64,
    ch: u8,
    identifier_map: std.StringHashMap(token.TokenType),

    pub fn init(input: []const u8) !Lexer {
        var lexer = Lexer{
            .input = input,
            .position = 0,
            .read_position = 0,
            .ch = 0,
            .identifier_map = std.StringHashMap(token.TokenType).init(std.heap.page_allocator),
        };
        try lexer.identifier_map.put("let", token.TokenType.LET);
        try lexer.identifier_map.put("fn", token.TokenType.FUNCTION);
        try lexer.identifier_map.put("if", token.TokenType.IF);
        try lexer.identifier_map.put("else", token.TokenType.ELSE);
        try lexer.identifier_map.put("true", token.TokenType.TRUE);
        try lexer.identifier_map.put("false", token.TokenType.FALSE);
        try lexer.identifier_map.put("return", token.TokenType.RETURN);
        lexer.read_char();
        return lexer;
    }

    const This = @This();

    pub fn read_char(self: *This) void {
        if (self.read_position >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.read_position];
        }
        self.position = self.read_position;
        self.read_position += 1;
    }

    pub fn read_identifier(self: *This) []const u8 {
        const position = self.position;
        while (self.is_letter()) {
            self.read_char();
        }
        return self.input[position..self.position];
    }

    pub fn is_letter(self: *This) bool {
        return ((self.ch >= 'a') and (self.ch <= 'z')) or ((self.ch >= 'A') and (self.ch <= 'Z')) or self.ch == '_';
    }

    pub fn lookup_ident(self: This, literal: []const u8) ?token.TokenType {
        const tokenType = self.identifier_map.get(literal);
        return tokenType;
    }

    pub fn skip_whitespace(self: *This) void {
        while (self.ch == ' ' or self.ch == '\t' or self.ch == '\n' or self.ch == '\r')
            self.read_char();
    }

    pub fn is_digit(self: This) bool {
        return self.ch >= '0' and self.ch <= '9';
    }

    pub fn read_number(self: *This) []const u8 {
        const position = self.position;
        while (self.is_digit())
            self.read_char();
        return self.input[position..self.position];
    }

    pub fn peek_char(self: This) u8 {
        if (self.read_position >= self.input.len) {
            return 0;
        } else {
            return self.input[self.read_position];
        }
    }

    pub fn next_token(self: *This) token.Token {
        self.skip_whitespace();
        var tok: token.Token = undefined;
        switch (self.ch) {
            '=' => {
                if (self.peek_char() == '=') {
                    self.read_char();
                    tok = token.Token.init(token.TokenType.EQ, "==");
                } else tok = token.Token.init(token.TokenType.ASSIGN, "=");
            },
            ';' => tok = token.Token.init(token.TokenType.SEMICOLON, ";"),
            '(' => tok = token.Token.init(token.TokenType.LPAREN, "("),
            ')' => tok = token.Token.init(token.TokenType.RPAREN, ")"),
            ',' => tok = token.Token.init(token.TokenType.COMMA, ","),
            '+' => tok = token.Token.init(token.TokenType.PLUS, "+"),
            '-' => tok = token.Token.init(token.TokenType.MINUS, "-"),
            '!' => {
                if (self.peek_char() == '=') {
                    self.read_char();
                    tok = token.Token.init(token.TokenType.NOT_EQ, "!=");
                } else tok = token.Token.init(token.TokenType.BANG, "!");
            },
            '*' => tok = token.Token.init(token.TokenType.ASTERISK, "*"),
            '/' => tok = token.Token.init(token.TokenType.SLASH, "/"),
            '<' => {
                if (self.peek_char() == '=') {
                    self.read_char();
                    tok = token.Token.init(token.TokenType.LT_EQ, "<=");
                } else tok = token.Token.init(token.TokenType.LT, "<");
            },
            '>' => {
                if (self.peek_char() == '=') {
                    self.read_char();
                    tok = token.Token.init(token.TokenType.GT_EQ, ">=");
                } else tok = token.Token.init(token.TokenType.GT, ">");
            },
            '{' => tok = token.Token.init(token.TokenType.LBRACE, "{"),
            '}' => tok = token.Token.init(token.TokenType.RBRACE, "}"),
            0 => tok = token.Token.init(token.TokenType.EOF, ""),
            else => {
                if (self.is_letter()) {
                    const literal = self.read_identifier();
                    const tokenType = self.lookup_ident(literal) orelse token.TokenType.IDENT;
                    return token.Token.init(tokenType, literal);
                } else if (self.is_digit()) {
                    return token.Token.init(token.TokenType.INT, self.read_number());
                } else {
                    tok = token.Token.init(
                        token.TokenType.ILLEGAL,
                        self.input[self.position .. self.position + 1],
                    );
                }
            },
        }

        self.read_char();
        return tok;
    }
};

//******************************************** TEST *********************************************
const test_ = struct {
    expectedType: token.TokenType,
    expectedLiteral: []const u8,
};

test "Test NextToken function: Single Character" {
    const input = "=+(){}";
    const tests = [_]test_{
        test_{ .expectedType = token.TokenType.ASSIGN, .expectedLiteral = "=" },
        test_{ .expectedType = token.TokenType.PLUS, .expectedLiteral = "+" },
        test_{ .expectedType = token.TokenType.LPAREN, .expectedLiteral = "(" },
        test_{ .expectedType = token.TokenType.RPAREN, .expectedLiteral = ")" },
        test_{ .expectedType = token.TokenType.LBRACE, .expectedLiteral = "{" },
        test_{ .expectedType = token.TokenType.RBRACE, .expectedLiteral = "}" },
        test_{ .expectedType = token.TokenType.EOF, .expectedLiteral = "" },
    };

    var lexer: Lexer = try Lexer.init(input);
    for (tests) |t| {
        const tok = lexer.next_token();
        // test the type
        //std.debug.print("{s}:{} but {s}:{}\n", .{ t.expectedLiteral, t.expectedType, tok.literal, tok.type_ });

        try std.testing.expect(t.expectedType == tok.type_);
        // assert the type
        try std.testing.expect(std.mem.eql(u8, t.expectedLiteral, tok.literal));
    }
}

test "Test NextToken function: 2 Character Token" {
    const input = "=+ 5 <= 10 >= 5;";

    const tests = [_]test_{
        test_{ .expectedType = token.TokenType.ASSIGN, .expectedLiteral = "=" },
        test_{ .expectedType = token.TokenType.PLUS, .expectedLiteral = "+" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "5" },
        test_{ .expectedType = token.TokenType.LT_EQ, .expectedLiteral = "<=" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "10" },
        test_{ .expectedType = token.TokenType.GT_EQ, .expectedLiteral = ">=" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "5" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.EOF, .expectedLiteral = "" },
    };

    var lexer: Lexer = try Lexer.init(input);
    for (tests) |t| {
        const tok = lexer.next_token();
        // test the type
        // std.debug.print("{s}:{} but {s}:{}\n", .{ t.expectedLiteral, t.expectedType, tok.literal, tok.type_ });

        try std.testing.expect(t.expectedType == tok.type_);
        // assert the type
        try std.testing.expect(std.mem.eql(u8, t.expectedLiteral, tok.literal));
    }
}

test "Test NextToken function: Literals" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\let add = fn(x, y){
        \\  x + y;
        \\};
        \\let result = add(five, ten);
    ;
    const tests = [_]test_{
        test_{ .expectedType = token.TokenType.LET, .expectedLiteral = "let" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "five" },
        test_{ .expectedType = token.TokenType.ASSIGN, .expectedLiteral = "=" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "5" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.LET, .expectedLiteral = "let" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "ten" },
        test_{ .expectedType = token.TokenType.ASSIGN, .expectedLiteral = "=" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "10" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.LET, .expectedLiteral = "let" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "add" },
        test_{ .expectedType = token.TokenType.ASSIGN, .expectedLiteral = "=" },
        test_{ .expectedType = token.TokenType.FUNCTION, .expectedLiteral = "fn" },
        test_{ .expectedType = token.TokenType.LPAREN, .expectedLiteral = "(" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "x" },
        test_{ .expectedType = token.TokenType.COMMA, .expectedLiteral = "," },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "y" },
        test_{ .expectedType = token.TokenType.RPAREN, .expectedLiteral = ")" },
        test_{ .expectedType = token.TokenType.LBRACE, .expectedLiteral = "{" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "x" },
        test_{ .expectedType = token.TokenType.PLUS, .expectedLiteral = "+" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "y" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.RBRACE, .expectedLiteral = "}" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.LET, .expectedLiteral = "let" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "result" },
        test_{ .expectedType = token.TokenType.ASSIGN, .expectedLiteral = "=" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "add" },
        test_{ .expectedType = token.TokenType.LPAREN, .expectedLiteral = "(" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "five" },
        test_{ .expectedType = token.TokenType.COMMA, .expectedLiteral = "," },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "ten" },
        test_{ .expectedType = token.TokenType.RPAREN, .expectedLiteral = ")" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.EOF, .expectedLiteral = "" },
    };

    var lexer: Lexer = try Lexer.init(input);
    for (tests) |t| {
        const tok = lexer.next_token();
        // test the type
        // std.debug.print("{s}:{} but {s}:{}\n", .{ t.expectedLiteral, t.expectedType, tok.literal, tok.type_ });
        try std.testing.expect(t.expectedType == tok.type_);
        // assert the type
        try std.testing.expect(std.mem.eql(u8, t.expectedLiteral, tok.literal));
    }
}

test "Test NextToken function: all types" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\let add = fn(x, y){
        \\  x + y;
        \\};
        \\let result = add(five, ten);
        \\!-/*5;
        \\5 < 10 > 5;
        \\if(5 < 10) {
        \\      return true;
        \\} else {
        \\      return false;
        \\}
        \\ 10 == 10;
        \\ 10 != 9;
    ;
    const tests = [_]test_{
        test_{ .expectedType = token.TokenType.LET, .expectedLiteral = "let" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "five" },
        test_{ .expectedType = token.TokenType.ASSIGN, .expectedLiteral = "=" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "5" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.LET, .expectedLiteral = "let" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "ten" },
        test_{ .expectedType = token.TokenType.ASSIGN, .expectedLiteral = "=" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "10" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.LET, .expectedLiteral = "let" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "add" },
        test_{ .expectedType = token.TokenType.ASSIGN, .expectedLiteral = "=" },
        test_{ .expectedType = token.TokenType.FUNCTION, .expectedLiteral = "fn" },
        test_{ .expectedType = token.TokenType.LPAREN, .expectedLiteral = "(" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "x" },
        test_{ .expectedType = token.TokenType.COMMA, .expectedLiteral = "," },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "y" },
        test_{ .expectedType = token.TokenType.RPAREN, .expectedLiteral = ")" },
        test_{ .expectedType = token.TokenType.LBRACE, .expectedLiteral = "{" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "x" },
        test_{ .expectedType = token.TokenType.PLUS, .expectedLiteral = "+" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "y" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.RBRACE, .expectedLiteral = "}" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.LET, .expectedLiteral = "let" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "result" },
        test_{ .expectedType = token.TokenType.ASSIGN, .expectedLiteral = "=" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "add" },
        test_{ .expectedType = token.TokenType.LPAREN, .expectedLiteral = "(" },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "five" },
        test_{ .expectedType = token.TokenType.COMMA, .expectedLiteral = "," },
        test_{ .expectedType = token.TokenType.IDENT, .expectedLiteral = "ten" },
        test_{ .expectedType = token.TokenType.RPAREN, .expectedLiteral = ")" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.BANG, .expectedLiteral = "!" },
        test_{ .expectedType = token.TokenType.MINUS, .expectedLiteral = "-" },
        test_{ .expectedType = token.TokenType.SLASH, .expectedLiteral = "/" },
        test_{ .expectedType = token.TokenType.ASTERISK, .expectedLiteral = "*" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "5" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "5" },
        test_{ .expectedType = token.TokenType.LT, .expectedLiteral = "<" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "10" },
        test_{ .expectedType = token.TokenType.GT, .expectedLiteral = ">" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "5" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.IF, .expectedLiteral = "if" },
        test_{ .expectedType = token.TokenType.LPAREN, .expectedLiteral = "(" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "5" },
        test_{ .expectedType = token.TokenType.LT, .expectedLiteral = "<" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "10" },
        test_{ .expectedType = token.TokenType.RPAREN, .expectedLiteral = ")" },
        test_{ .expectedType = token.TokenType.LBRACE, .expectedLiteral = "{" },
        test_{ .expectedType = token.TokenType.RETURN, .expectedLiteral = "return" },
        test_{ .expectedType = token.TokenType.TRUE, .expectedLiteral = "true" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.RBRACE, .expectedLiteral = "}" },
        test_{ .expectedType = token.TokenType.ELSE, .expectedLiteral = "else" },
        test_{ .expectedType = token.TokenType.LBRACE, .expectedLiteral = "{" },
        test_{ .expectedType = token.TokenType.RETURN, .expectedLiteral = "return" },
        test_{ .expectedType = token.TokenType.FALSE, .expectedLiteral = "false" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.RBRACE, .expectedLiteral = "}" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "10" },
        test_{ .expectedType = token.TokenType.EQ, .expectedLiteral = "==" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "10" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "10" },
        test_{ .expectedType = token.TokenType.NOT_EQ, .expectedLiteral = "!=" },
        test_{ .expectedType = token.TokenType.INT, .expectedLiteral = "9" },
        test_{ .expectedType = token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        test_{ .expectedType = token.TokenType.EOF, .expectedLiteral = "" },
    };

    var lexer: Lexer = try Lexer.init(input);
    for (tests) |t| {
        const tok = lexer.next_token();
        // test the type
        // std.debug.print("{s}:{} but {s}:{}\n", .{ t.expectedLiteral, t.expectedType, tok.literal, tok.type_ });
        try std.testing.expect(t.expectedType == tok.type_);
        // assert the type
        try std.testing.expect(std.mem.eql(u8, t.expectedLiteral, tok.literal));
    }
}
