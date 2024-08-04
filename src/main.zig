const std = @import("std");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("Server starting...\n", .{});

    const serv_addr = try std.net.Address.parseIp4("127.0.0.1", 6767);
    var listener = try serv_addr.listen(.{ .reuse_address = true });

    std.debug.print("Server started listening on {}\n", .{serv_addr});

    while (listener.accept()) |conn| {
        std.debug.print("New connection from {}\n", .{conn.address});
        var req_body: [4096]u8 = undefined;
        var req_body_total: usize = 0;

        while (conn.stream.read(req_body[req_body_total..])) |reqBodyLength| {
            if (reqBodyLength == 0) break;
            req_body_total += reqBodyLength;

            if (std.mem.containsAtLeast(u8, req_body[0..req_body_total], 1, "\r\n\r\n")) {
                break;
            }
        } else |read_err| {
            return read_err;
        }
        const recv_data = req_body[0..req_body_total];
        if (recv_data.len == 0) {
            std.debug.print("Got connection but no header!\n", .{});
            continue;
        }

        var split_data = std.mem.splitSequence(u8, recv_data, "\r\n\r\n");
        if (split_data.next()) |headers| {
            var headerIterator = std.mem.tokenizeSequence(u8, headers, "\r\n");

            while (headerIterator.next()) |line| {
                var headerLine = std.mem.splitAny(u8, line, ":");
                std.debug.print("{s}\n", .{headerLine.first()});
                std.debug.print("{s}\n", .{headerLine.rest()});
                std.debug.print("------------\n", .{});
            }
        }
        if (split_data.next()) |body| {
            std.debug.print("|{s}|\n", .{body});
        }
    } else |err| {
        std.debug.print("error while accepting connection {}\n", .{err});
    }
}
