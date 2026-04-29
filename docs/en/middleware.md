# Middleware

Nexus supports middleware at two levels:

- Global: `Nexus.Middleware`
- Service-local: `Service.Middleware`

Both support:

- `Inbound` list
- `Outbound` list

Each middleware function signature:

```luau
function(player: Player?, data: any): (boolean, any?)
```

- Return `false` to reject/drop the payload.
- Return `true, newData` to pass transformed payload.
- Return `true, nil` to pass original payload.

This makes middleware useful for shared validation, payload shaping, and cross-cutting concerns that should not be repeated in every remote handler.

## Example

```luau
Nexus.Middleware.Outbound = {
	function(player, data)
		if type(data) ~= "table" then
			return false, nil
		end
		data._sentAt = os.clock()
		return true, data
	end,
}
```

## Order

- Inbound: global -> service
- Outbound: service -> global

Use service middleware for domain-specific rules and global middleware for cross-cutting concerns like tracing, rate-limit tags, or common validation.

## License

MIT. See `LICENSE`.
