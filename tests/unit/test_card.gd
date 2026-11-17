extends GutTest
## Kart kaydının birim testleri.


func test_from_dict_after_to_dict_keeps_type_and_value() -> void:
	var card := Card.new(Card.Type.SEND_BACK, 4)

	var copy := Card.from_dict(card.to_dict())

	assert_eq(copy.type, card.type)
	assert_eq(copy.value, card.value)


func test_from_dict_with_unknown_type_returns_null() -> void:
	assert_null(Card.from_dict({"type": "teleport", "value": 1}))
