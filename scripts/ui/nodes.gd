class_name Nodes
extends RefCounted
## Düğüm ağacıyla ilgili küçük ortak işler.


## Bütün çocuk düğümleri hemen ağaçtan çıkarır ve siler; yerlerine yenileri aynı karede
## eklenebilir.
static func free_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
