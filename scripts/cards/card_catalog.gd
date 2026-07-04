extends RefCounted
class_name CardCatalog


static func load_card_definition(resource_path: String) -> CardDefinition:
	var resource := load(resource_path)
	if resource is CardDefinition:
		return resource
	push_error("Resource is not a CardDefinition: %s" % resource_path)
	return null


static func load_deck_definition(resource_path: String) -> DeckDefinition:
	var resource := load(resource_path)
	if resource is DeckDefinition:
		return resource
	push_error("Resource is not a DeckDefinition: %s" % resource_path)
	return null
