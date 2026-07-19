extends Control

@export var credits_path: String = "res://credits.md"
@export var scroll_speed: float = 35.0

@onready var start_scroll_button: Button = %StartScrollButton
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var rich_text_label: RichTextLabel = %RichTextLabel

var auto_scrolling: bool = false
var scroll_amount: float = 0.0

func _ready() -> void:
	rich_text_label.bbcode_enabled = true
	rich_text_label.fit_content = true
	rich_text_label.scroll_active = false

	_load_credits()

	start_scroll_button.pressed.connect(_toggle_auto_scroll)
	scroll_container.gui_input.connect(_on_user_input)
	rich_text_label.gui_input.connect(_on_user_input)


func _process(delta: float) -> void:
	if not auto_scrolling:
		return

	var scrollbar := scroll_container.get_v_scroll_bar()
	var max_scroll := int(scrollbar.max_value - scrollbar.page)

	if scroll_container.scroll_vertical >= max_scroll:
		auto_scrolling = false
		return

	scroll_amount += scroll_speed * delta
	scroll_container.scroll_vertical = int(scroll_amount)


func _load_credits() -> void:
	if not FileAccess.file_exists(credits_path):
		rich_text_label.text = "Credits file not found:\n" + credits_path
		return

	var markdown := FileAccess.get_file_as_string(credits_path)

	rich_text_label.clear()
	rich_text_label.append_text(markdown_to_bbcode(markdown))

	await get_tree().process_frame
	scroll_container.scroll_vertical = 0
	scroll_amount = 0.0


func _toggle_auto_scroll() -> void:
	if not auto_scrolling:
		scroll_amount = float(scroll_container.scroll_vertical)
		auto_scrolling = true
	else:
		auto_scrolling = false

func _pause_auto_scroll() -> void:
	auto_scrolling = false


func _on_user_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP \
		or event.button_index == MOUSE_BUTTON_WHEEL_DOWN \
		or event.button_index == MOUSE_BUTTON_LEFT:
			_pause_auto_scroll()

	elif event is InputEventPanGesture:
		_pause_auto_scroll()

	elif event is InputEventScreenDrag:
		_pause_auto_scroll()


func markdown_to_bbcode(markdown: String) -> String:
	var lines := markdown.replace("\r\n", "\n").split("\n")
	var result: Array[String] = []

	var in_code_block := false
	var in_quote := false

	for raw_line in lines:
		var line: String = raw_line

		if line.strip_edges().begins_with("```"):
			if not in_code_block:
				result.append("[code]")
				in_code_block = true
			else:
				result.append("[/code]")
				in_code_block = false
			continue

		if in_code_block:
			result.append(line)
			continue

		line = line.strip_edges(false, true)

		if line.strip_edges() == "---" or line.strip_edges() == "***":
			result.append("[center]────────────[/center]")
			continue

		if line.begins_with("> "):
			if not in_quote:
				result.append("[indent][i]")
				in_quote = true

			result.append(markdown_inline_to_bbcode(line.substr(2)))
			continue
		else:
			if in_quote:
				result.append("[/i][/indent]")
				in_quote = false

		if line.begins_with("#### "):
			result.append("[font_size=8][color=#40f57f][b]" + markdown_inline_to_bbcode(line.substr(5)) + "[/b][/color][/font_size]")
		elif line.begins_with("### "):
			result.append("[font_size=10][color=#0fbf4d][b]" + markdown_inline_to_bbcode(line.substr(4)) + "[/b][/color][/font_size]")
		elif line.begins_with("## "):
			result.append("[font_size=12][color=#209649][b]" + markdown_inline_to_bbcode(line.substr(3)) + "[/b][/color][/font_size]")
		elif line.begins_with("# "):
			result.append("[font_size=14][color=#115c2b][b]" + markdown_inline_to_bbcode(line.substr(2)) + "[/b][/color][/font_size]")
		elif line.begins_with("- "):
			result.append("• " + markdown_inline_to_bbcode(line.substr(2)))
		elif line.begins_with("* "):
			result.append("• " + markdown_inline_to_bbcode(line.substr(2)))
		elif _is_numbered_list_item(line):
			var dot_index := line.find(". ")
			result.append(line.substr(0, dot_index + 2) + markdown_inline_to_bbcode(line.substr(dot_index + 2)))
		else:
			result.append(markdown_inline_to_bbcode(line))

	if in_quote:
		result.append("[/i][/indent]")

	if in_code_block:
		result.append("[/code]")

	return "\n".join(result)


func markdown_inline_to_bbcode(text: String) -> String:
	var output := text

	output = _convert_markdown_links(output)
	output = _replace_inline_pairs(output, "**", "[b]", "[/b]")
	output = _replace_inline_pairs(output, "__", "[b]", "[/b]")
	output = _replace_inline_pairs(output, "`", "[code]", "[/code]")
	output = _replace_inline_pairs(output, "*", "[i]", "[/i]")
	#output = _replace_inline_pairs(output, "_", "[i]", "[/i]")

	return output


func _replace_inline_pairs(text: String, marker: String, open_tag: String, close_tag: String) -> String:
	var result := ""
	var split_text := text.split(marker)
	var opened := false

	for i in split_text.size():
		result += split_text[i]

		if i < split_text.size() - 1:
			result += close_tag if opened else open_tag
			opened = not opened

	if opened:
		result += close_tag

	return result


func _convert_markdown_links(text: String) -> String:
	var result := text

	while true:
		var label_start := result.find("[")
		if label_start == -1:
			break

		var label_end := result.find("]", label_start)
		if label_end == -1:
			break

		var url_start := result.find("(", label_end)
		if url_start != label_end + 1:
			break

		var url_end := result.find(")", url_start)
		if url_end == -1:
			break

		var label := result.substr(label_start + 1, label_end - label_start - 1)
		var url := result.substr(url_start + 1, url_end - url_start - 1)

		var bbcode_link := "[url=" + url + "]" + label + "[/url]"

		result = result.substr(0, label_start) + bbcode_link + result.substr(url_end + 1)

	return result


func _is_numbered_list_item(line: String) -> bool:
	var dot_index := line.find(". ")

	if dot_index <= 0:
		return false

	var number_part := line.substr(0, dot_index)

	return number_part.is_valid_int()


func _on_back_button_pressed() -> void:
	get_parent().hide()
