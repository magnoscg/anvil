---
name: swift-adapter
description: Use Adapter in Swift to translate a legacy or third-party interface into the small domain capability an iOS feature needs.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Adapter

## Intent

Translate one interface, data shape, or convention into another without leaking the source model into feature code.

## When to use it

Use it around SDKs, generated clients, legacy storage, and platform callbacks whose vocabulary or error model differs from the domain.

## When to avoid it

Avoid it when the source already satisfies the domain boundary or when changing the source is cheaper and under your control.

## Participants

- Target protocol expected by the feature.
- Adaptee with an incompatible interface.
- Adapter that maps calls, data, and failures.

## Example

```swift
struct ProductPrice: Equatable {
    let productID: String
    let cents: Int
}

protocol PriceLoading {
    func price(for productID: String) -> ProductPrice?
}

final class LegacyPriceStore {
    private let rows: [[String: String]] = [
        ["sku": "pro.monthly", "minor_units": "799"]
    ]

    func lookup(sku: String) -> [String: String]? {
        rows.first { $0["sku"] == sku }
    }
}

struct LegacyPriceAdapter: PriceLoading {
    let store: LegacyPriceStore

    func price(for productID: String) -> ProductPrice? {
        guard
            let row = store.lookup(sku: productID),
            let rawCents = row["minor_units"],
            let cents = Int(rawCents)
        else { return nil }

        return ProductPrice(productID: productID, cents: cents)
    }
}

let loader = LegacyPriceAdapter(store: LegacyPriceStore())
precondition(loader.price(for: "pro.monthly") == ProductPrice(productID: "pro.monthly", cents: 799))
```

## Trade-offs

The domain stays stable and source quirks are centralized. Mapping code must be maintained and can conceal lossy conversions unless they are explicit.

## Testing strategy

Test every mapping branch, malformed source value, missing field, unit conversion, and error translation. Use captured source fixtures at the adapter boundary.

## Related patterns

Facade offers a simpler subsystem API without necessarily translating models. Proxy preserves the interface while controlling access. Anti-corruption layers often contain several adapters.
