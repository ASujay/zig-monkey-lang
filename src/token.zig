const std = @import("std");

pub const TokenType = enum(u8) {
    ILLEGAL,
    EOF,

    IDENT,
    INT,

    ASSIGN,
    PLUS,
    MINUS,
    BANG,
    ASTERISK,
    SLASH,

    LT,
    GT,

    COMMA,
    SEMICOLON,

    LPAREN,
    RPAREN,
    LBRACE,
    RBRACE,

    EQ,
    NOT_EQ,

    LT_EQ,
    GT_EQ,

    FUNCTION,
    LET,
    TRUE,
    FALSE,
    IF,
    ELSE,
    RETURN,
};

pub const Token = struct {
    type_: TokenType,
    literal: []const u8,

    const This = @This();
    pub fn init(type_: TokenType, literal: []const u8) Token {
        return Token{
            .type_ = type_,
            .literal = literal,
        };
    }

    pub fn to_string(self: This) void {
        std.debug.print("{{ type: {}, literal: {s} }}\n", .{ self.type_, self.literal });
    }
};
