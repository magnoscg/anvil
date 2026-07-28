# Performance Guide

> Performance profiling, optimization patterns, and memory management.

## Overview

This guide covers performance profiling with Instruments, SwiftUI optimization, Swift code performance, and memory management patterns.

---

## Profiling with Instruments

### Available Templates

| Template | Use Case |
|----------|----------|
| Time Profiler | CPU hotspots, slow functions |
| Allocations | Memory allocation patterns |
| Leaks | Memory leak detection |
| SwiftUI | View body evaluations |
| Core Animation | Frame drops, GPU usage |
| Energy Log | Battery consumption |

### Using xctrace CLI

```bash
# Record Time Profiler for 10 seconds
xcrun xctrace record \
    --template "Time Profiler" \
    --device "<SIMULATOR_UDID>" \
    --attach "<BUNDLE_ID>" \
    --time-limit 10s \
    --output /tmp/profile.trace

# Record memory allocations
xcrun xctrace record \
    --template "Allocations" \
    --device "<SIMULATOR_UDID>" \
    --launch -- <BUNDLE_ID> \
    --output /tmp/memory.trace

# Export trace data for analysis
xcrun xctrace export \
    --input /tmp/profile.trace \
    --output /tmp/profile_export
```

---

## SwiftUI Performance

### Minimize View Body Evaluations

```swift
// WRONG: Expensive computation in body
var body: some View {
    let sortedItems = items.sorted { $0.date > $1.date }
    let filteredItems = sortedItems.filter { $0.isActive }

    List(filteredItems) { item in
        ItemRow(item: item)
    }
}

// RIGHT: Move computation to ViewModel
var body: some View {
    List(viewModel.processedItems) { item in
        ItemRow(item: item)
    }
}
```

### Use LazyVStack for Long Lists

```swift
// WRONG: VStack loads all items immediately
ScrollView {
    VStack {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}

// RIGHT: LazyVStack loads items on demand
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}
```

### Avoid Creating Objects in Body

```swift
// WRONG: DateFormatter created every render
var body: some View {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    Text(formatter.string(from: date))
}

// RIGHT: Static formatter
private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

var body: some View {
    Text(Self.dateFormatter.string(from: date))
}
```

### Use equatable() for Heavy Views

```swift
struct HeavyChartView: View, Equatable {
    let data: ChartData

    var body: some View {
        // Complex chart rendering
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data.id == rhs.data.id
    }
}

// Usage
HeavyChartView(data: chartData)
    .equatable()
```

### Image Loading Optimization

```swift
// WRONG: Large image loaded at full resolution
Image("large-photo")
    .resizable()
    .frame(width: 100, height: 100)

// RIGHT: AsyncImage with proper sizing
AsyncImage(url: imageURL) { phase in
    switch phase {
    case .success(let image):
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
    case .failure:
        Image(systemName: "photo")
    case .empty:
        ProgressView()
    @unknown default:
        EmptyView()
    }
}
.frame(width: 100, height: 100)
.clipped()
```

### Use drawingGroup() for Complex Graphics

```swift
ZStack {
    ForEach(0..<100) { index in
        Circle()
            .fill(colors[index])
            .blur(radius: 10)
    }
}
.drawingGroup()
```

---

## Swift Performance

### Prefer Value Types

```swift
// PREFER: Struct (stack allocated, no reference counting)
struct Point {
    var x: Double
    var y: Double
}

// AVOID: Class when not needed (heap allocated, ARC overhead)
class Point {
    var x: Double
    var y: Double
}
```

### Copy-on-Write Awareness

```swift
// Swift collections use COW - copies are cheap
var array1 = [1, 2, 3]
var array2 = array1  // No copy yet - shared storage

array2.append(4)  // NOW copy happens (mutation)
```

### Use Lazy Collections

```swift
// SLOW: Creates intermediate array
let filtered = items.filter { $0.isActive }.map { $0.name }

// FASTER: Lazy evaluation (no intermediate array)
let filtered = items.lazy.filter { $0.isActive }.map { $0.name }

// But only beneficial if you don't need all results
for name in filtered.prefix(10) {
    print(name)
}
```

### Avoid String Interpolation in Loops

```swift
// SLOW: String allocation every iteration
var result = ""
for item in items {
    result += "\(item.name), "
}

// FASTER: Use array join
let result = items.map(\.name).joined(separator: ", ")

// Or StringBuilder pattern
var parts: [String] = []
parts.reserveCapacity(items.count)
for item in items {
    parts.append(item.name)
}
let result = parts.joined(separator: ", ")
```

---

## Memory Management

### Retain Cycle Prevention

```swift
// WRONG: Strong reference cycle
class ViewModel {
    var onComplete: (() -> Void)?

    func setup() {
        onComplete = {
            self.handleComplete()
        }
    }
}

// RIGHT: Weak capture
class ViewModel {
    var onComplete: (() -> Void)?

    func setup() {
        onComplete = { [weak self] in
            self?.handleComplete()
        }
    }
}
```

### When to Use [weak self]

| Context | Use weak self? |
|---------|----------------|
| Network callbacks | Yes |
| Timers | Yes |
| NotificationCenter | Yes |
| Combine sinks | Yes |
| Stored closures | Yes |
| map/filter/forEach | No |
| .task { } in View | No (auto-cancelled) |

### Timer Leak Pattern

```swift
class ViewModel {
    private var timer: Timer?

    func startTimer() {
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            self?.tick()
        }
    }

    deinit {
        timer?.invalidate()
    }
}
```

### Observer Cleanup

```swift
class ViewModel {
    private var observer: NSObjectProtocol?

    func setup() {
        observer = NotificationCenter.default.addObserver(
            forName: .someNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleNotification()
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
```

---

## Performance Checklist

### Pre-Release

- [ ] Profile with Time Profiler - no obvious hotspots
- [ ] Profile with Allocations - no unexpected growth
- [ ] Check for memory leaks with Leaks template
- [ ] Test scrolling performance at 60fps
- [ ] Verify app launch time < 400ms

### SwiftUI Specific

- [ ] Using LazyVStack/LazyHStack for lists
- [ ] No expensive computations in body
- [ ] Images properly sized
- [ ] Heavy views use .equatable()

---

## Quick Reference

| Problem | Solution |
|---------|----------|
| Slow scrolling | LazyVStack, image optimization |
| High CPU | Move computation out of body |
| Memory growth | Check for retain cycles |
| Slow startup | Defer non-critical work |
| Battery drain | Reduce timers, use push over polling |
