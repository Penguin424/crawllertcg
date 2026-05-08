# TCGS App - Database Schema
## Current: Hive (NoSQL) → Target: REST API

---

## BOX 1: `cards`

### Model: `CardModel` (typeId: 0)

| Field | Type | Nullable | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | String | No | (UUID) | Primary key - unique card identifier |
| `name` | String | No | required | Card name |
| `dateAdded` | DateTime | No | required | Timestamp when card was added |
| `quantity` | int | No | 1 | Number of cards in collection |
| `expansion` | String? | Yes | null | Set/expansion name (e.g., "002/004") |
| `rarity` | String? | Yes | null | Card rarity |
| `notes` | String? | Yes | null | User notes |
| `imageUrl` | String? | Yes | null | URL to card image |
| `price` | String? | Yes | null | Price as string (legacy - e.g., "$12.99") |
| `cardPageUrl` | String? | Yes | null | URL to card page |
| `cardApiId` | String? | Yes | null | API identifier from external service |
| `source` | String? | Yes | null | Source of the card data |
| `priceValue` | double? | Yes | null | Numeric price value (parsed from price field) |

### Key Operations:
- CRUD via `cardsBox.put(key, card)` and `cardsBox.delete(key)`
- Cards identified by `id` (UUID format)
- Supports search by name and expansion

---

## BOX 2: `collection_snapshots`

### Model: `CollectionSnapshot` (typeId: 1)

| Field | Type | Nullable | Default | Description |
|-------|------|----------|---------|-------------|
| `date` | DateTime | No | required | Snapshot date (key format: `YYYY-MM-DD`) |
| `totalValue` | double | No | required | Total collection value |
| `uniqueCards` | int | No | required | Count of unique card types |
| `totalCards` | int | No | required | Total cards count (including quantities) |

### Key Operations:
- Uses date as key (format: `YYYY-MM-DD`)
- `recordDailySnapshotIfNeeded()` - idempotent daily snapshot
- `latestSnapshot` - retrieves most recent snapshot

---

## Relationships
**None.** This is a NoSQL database:
- Cards are independent entities
- Collection snapshots are standalone records (no link to cards table)
- Snapshots are point-in-time aggregations

---

## API Endpoints Expected

### Cards
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/cards` | List all cards |
| GET | `/cards/{id}` | Get single card |
| POST | `/cards` | Create new card |
| PUT | `/cards/{id}` | Update card |
| DELETE | `/cards/{id}` | Delete card |

### Collection Snapshots
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/collection-snapshots` | List all snapshots |
| GET | `/collection-snapshots/{date}` | Get snapshot by date |
| POST | `/collection-snapshots` | Create snapshot |

---

## Migration Notes

1. **Price field**: `price` (String) is legacy. New API should use `priceValue` (double)
2. **Dates**: Send as ISO 8601 strings in API calls (e.g., `2026-05-08T12:00:00Z`)
3. **No foreign keys**: Structure is denormalized, no referential integrity needed
4. **Authentication**: Not implemented in current Hive version - may need to add

---

## Project Files Reference

```
lib/services/database_service.dart   - Main database service (Hive)
lib/models/card_model.dart           - CardModel class
lib/models/collection_snapshot.dart   - CollectionSnapshot class
lib/providers/database_provider.dart - Database provider
lib/models/card_model.g.dart         - Generated Hive adapter
lib/models/collection_snapshot.g.dart - Generated Hive adapter
```

---

## TypeScript/Flutter Model Reference

### CardModel Interface
```typescript
interface CardModel {
  id: string;           // UUID
  name: string;
  dateAdded: Date;
  quantity: number;
  expansion?: string;
  rarity?: string;
  notes?: string;
  imageUrl?: string;
  price?: string;       // legacy
  cardPageUrl?: string;
  cardApiId?: string;
  source?: string;
  priceValue?: number;
}
```

### CollectionSnapshot Interface
```typescript
interface CollectionSnapshot {
  date: Date;
  totalValue: number;
  uniqueCards: number;
  totalCards: number;
}
```