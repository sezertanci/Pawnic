extends GutTest
## "Nasıl oynanır" listesi: gruplar kapalı açılır, aynı anda yalnızca bir grup açık kalır, açık
## gruba yeniden dokununca kapanır ve collapse_all hepsini kapatır.

const GROUP_COUNT := 5

var _list: RuleList


func before_each() -> void:
	_list = RuleList.new()
	add_child_autofree(_list)


func test_all_groups_start_closed() -> void:
	var groups := _groups()

	assert_eq(groups.size(), GROUP_COUNT)
	for group: RuleGroup in groups:
		assert_false(group.is_open())


func test_opening_group_closes_other() -> void:
	var groups := _groups()
	groups[0].header.pressed.emit()

	groups[1].header.pressed.emit()

	assert_false(groups[0].is_open())
	assert_true(groups[1].is_open())


func test_pressing_open_group_closes_it() -> void:
	var group := _groups()[2]
	group.header.pressed.emit()

	group.header.pressed.emit()

	assert_false(group.is_open())


func test_collapse_all_closes_open_group() -> void:
	var group := _groups()[4]
	group.header.pressed.emit()

	_list.collapse_all()

	assert_false(group.is_open())


func test_every_group_has_rows() -> void:
	for group: RuleGroup in _groups():
		assert_gt(group.content.get_child_count(), 0)


func _groups() -> Array[RuleGroup]:
	var groups: Array[RuleGroup] = []
	for child: Node in _list.get_children():
		groups.append(child as RuleGroup)
	return groups
