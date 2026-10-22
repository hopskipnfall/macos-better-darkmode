/// Maps `value` linearly to 0 (at `bright`) ... 1 (at `dark`), clamped.
/// Used by every heuristic so thresholds read as "fully bright at X, fully dark at Y".
public func ramp(_ value: Double, bright: Double, dark: Double) -> Double {
    guard bright != dark else { return value <= dark ? 1 : 0 }
    let t = (value - bright) / (dark - bright)
    return min(1, max(0, t))
}
