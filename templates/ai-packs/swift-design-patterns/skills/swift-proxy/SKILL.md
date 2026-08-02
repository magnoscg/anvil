---
name: swift-proxy
description: Use Proxy in Swift to control access to a capability for caching, authorization, laziness, or remote transport while preserving its interface.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Proxy

## Intent

Stand in for another object and decide when or whether the real operation proceeds.

## When to use it

Use it for lazy loading, access checks, request coalescing, local caching, or a remote boundary that should look like a domain capability.

## When to avoid it

Avoid it when the wrapper changes the capability's meaning or error model without making that policy visible. Hidden network or cache behavior can surprise callers.

## Participants

- Subject protocol shared by proxy and real subject.
- Real subject performing the operation.
- Proxy controlling access and optionally retaining state.
- Client using the subject boundary.

## Example

```swift
protocol AvatarLoading: AnyObject {
    func avatar(for userID: String) -> String
}

final class RemoteAvatarLoader: AvatarLoading {
    private(set) var requestCount = 0

    func avatar(for userID: String) -> String {
        requestCount += 1
        return "image-data:\(userID)"
    }
}

final class CachingAvatarProxy: AvatarLoading {
    private let remote: RemoteAvatarLoader
    private var cache: [String: String] = [:]

    init(remote: RemoteAvatarLoader) {
        self.remote = remote
    }

    func avatar(for userID: String) -> String {
        if let cached = cache[userID] {
            return cached
        }
        let loaded = remote.avatar(for: userID)
        cache[userID] = loaded
        return loaded
    }
}

let remote = RemoteAvatarLoader()
let proxy = CachingAvatarProxy(remote: remote)
_ = proxy.avatar(for: "user-1")
_ = proxy.avatar(for: "user-1")
precondition(remote.requestCount == 1)
```

## Trade-offs

Access policy is centralized and clients retain one interface. Latency, freshness, authorization, and identity can become implicit unless documented and observable.

## Testing strategy

Verify forwarding, denial, cache hit and miss, invalidation, real-subject failures, and duplicate requests. Use clocks or schedulers when policy is time based.

## Related patterns

Decorator always adds behavior around the call. Adapter changes the interface. Facade coordinates several subjects behind a task-level API.
