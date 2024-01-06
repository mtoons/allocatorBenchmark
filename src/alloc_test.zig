const std = @import("std");
// const zimalloc = @import("zimalloc");

const BenchmarkResult = struct {
    name: []const u8,
    time_nanoseconds: u64,
};
const Allocator = struct {
    name: []const u8,
    allocator: std.mem.Allocator,
};

fn benchmark(allocator: std.mem.Allocator) ![]BenchmarkResult {
    const random_allocation_number: usize = 100000;
    const max_random_allocation_size: u64 = 1000000;
    const arena_allocation_number: usize = 1000000;
    var result_array = [_]BenchmarkResult{
        BenchmarkResult{
            .name = "random allocation test",
            .time_nanoseconds = try randomAllocTest(allocator, random_allocation_number, max_random_allocation_size),
        },
        BenchmarkResult{
            .name = "arena allocation test",
            .time_nanoseconds = try arenaAllocationTest(allocator, arena_allocation_number),
        },
    };
    return result_array[0..];
}

fn benchmarkPrintResult(allocators: []Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    for (allocators) |allocator| {
        try stdout.print("{s}:\n", .{allocator.name});

        const benchmarks: []BenchmarkResult = try benchmark(allocator.allocator);

        for (benchmarks) |value| {
            try stdout.print("{s} {} nanoseconds\n", .{ value.name, value.time_nanoseconds });
        }

        try stdout.print("\n", .{});
    }
}

// pub fn main() !void {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer _ = gpa.deinit();
//     const general_purpose_allocator = gpa.allocator();
//
//     // var zm = try zimalloc.Allocator(.{}){};
//     // defer zm.deinit();
//     // const zig_malloc = zm.allocator();
//
//     var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//     const arena_allocator = arena.allocator();
//     defer arena.deinit();
//
//     var buffer: [1000000]u8 = undefined;
//     var fba = std.heap.FixedBufferAllocator.init(&buffer);
//     const fixed_buffer_allocator = fba.allocator();
//
//     var allocators_array = [_]Allocator{
//         Allocator{
//             .name = "page_allocator",
//             .allocator = std.heap.page_allocator,
//         },
//         Allocator{
//             .name = "GeneralPurposeAllocator",
//             .allocator = general_purpose_allocator,
//         },
//         Allocator{
//             .name = "c_allocator",
//             .allocator = std.heap.c_allocator,
//         },
//         // Allocator{
//         //     .name = "zimalloc",
//         //     .allocator = zig_malloc,
//         // },
//         Allocator{
//             .name = "ArenaAllocator",
//             .allocator = arena_allocator,
//         },
//         Allocator{
//             .name = "FixedBufferAllocator",
//             .allocator = fixed_buffer_allocator,
//         },
//     };
//     try benchmarkPrintResult(allocators_array[0..]);
// }

const RndGen = std.rand.DefaultPrng;

pub fn randomAllocTest(
    allocator: std.mem.Allocator,
    comptime number_of_allocation: usize,
    allocation_range: u64,
) !u64 {
    var rand = RndGen.init(1);
    var timer = blk: {
        const current = std.time.Instant.now() catch return error.TimerUnsupported;
        break :blk std.time.Timer{ .started = current, .previous = current };
    };

    var i: usize = 0;
    while (i < number_of_allocation) : (i += 1) {
        const memory = try allocation(allocator, std.rand.limitRangeBiased(
            u64,
            rand.random().int(u64),
            allocation_range,
        ));
        memory[1] = 5;
        allocator.free(memory);
    }

    return timer.read();
}

fn allocation(allocator: std.mem.Allocator, bytes: usize) ![]u8 {
    return try allocator.alloc(u8, bytes);
}

fn arenaAllocationTest(allocator: std.mem.Allocator, comptime number_of_allocation: usize) !u64 {
    var timer = blk: {
        const current = std.time.Instant.now() catch return error.TimerUnsupported;
        break :blk std.time.Timer{ .started = current, .previous = current };
    };

    var i: usize = 0;
    while (i < number_of_allocation) : (i += 1) {
        var arena = try arenaAllocation(allocator);
        const arena_allocator = arena.allocator();
        _ = try randomAllocTest(arena_allocator, 10, 100);
        arena.deinit();
    }

    return timer.read();
}

fn arenaAllocation(allocator: std.mem.Allocator) !std.heap.ArenaAllocator {
    return std.heap.ArenaAllocator.init(allocator);
}
