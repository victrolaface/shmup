class_name Component
extends Node

var entity: Node2D:
	get:
		return get_parent() as Node2D

static func of(node: Node, component_name: String) -> Node:
	return node.get_node_or_null(component_name)
