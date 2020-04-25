extends Node2D

var parser = preload("res://addons/godot-yaml/gdyaml.gdns").new()
var parts = {}

export(NodePath) var lines_slider
export(NodePath) var config_selector
export(NodePath) var textbox
export(NodePath) var generate_button
var lines_per_frame = 10
onready var line_container = $LineContainer
var lines = []

func _ready():
    get_node(lines_slider).connect("value_changed", self, "_slider_changed")
    get_node(config_selector).connect("item_selected", self, "_item_selected")
    get_node(generate_button).connect("pressed", self, "_press_button")
    for file in get_files("res://rules"):
        get_node(config_selector).add_item(file)

    yield(get_tree(), "idle_frame")
    yield(get_tree(), "idle_frame")
    # get_node(config_selector).select(0)
    get_node(config_selector).emit_signal("item_selected", 0)


func _slider_changed(value):
    self.lines_per_frame = value
    print(lines_per_frame)


func _item_selected(index):
    var file = File.new()
    var filename = "res://rules/{0}".format([
        get_node(config_selector).get_item_text(index)
    ])
    file.open(filename, File.READ)
    var content = file.get_as_text().strip_edges()
    file.close()
    get_node(textbox).text = content
    get_node(generate_button).emit_signal("pressed")

func _press_button():
    var center = Vector2(get_viewport_rect().end.x / 2, get_viewport_rect().end.y / 2)
    var bottom_center = Vector2(get_viewport_rect().end.x / 2, get_viewport_rect().end.y)
    var bottom_right = Vector2(get_viewport_rect().end.x / 3 * 2, get_viewport_rect().end.y)

    var config = parser.parse(get_node(textbox).text)

    # Null if yaml incorrect
    if config != null:
        print(config)
        # return
        lines = []
        for node in line_container.get_children():
            node.queue_free()

        var origin = center
        match config["origin"]:
            "center":
                origin = center
            "bottom center":
                origin = bottom_center
            "bottom right":
                origin = bottom_center

        lines = generate(
            origin,
            int(config["iterations"]),
            float(config["length_reduction"]),
            Color(config["color"]),
            float(config["width"]),
            Rule.new(config["rule"])
        )


func get_files(path):
    var files = []
    var dir = Directory.new()
    dir.open(path)
    dir.list_dir_begin()

    while true:
        var file = dir.get_next()
        if file == "":
            break
        elif not file.begins_with("."):
            files.append(file)

    dir.list_dir_end()
    return files


func _process(delta):
    # Test for escape to close application, space to reset our reference frame
    if Input.is_key_pressed(KEY_ESCAPE):
        get_tree().quit()

    if lines.empty():
        return
    for index in self.lines_per_frame:
        line_container.add_child(lines.pop_front())
        if lines.empty():
            break


func generate(start_position, iterations, length_reduction, color, width, rule):
    var length = -200
    var arrangement = rule.axiom
    for i in iterations:
        length *= length_reduction
        var new_arrangement = ""
        for character in arrangement:
            new_arrangement += rule.get_character(character)
        arrangement = new_arrangement


    var lines = []
    var from = start_position
    var rot = 0
    var cache_queue = []
    for index in arrangement:
        match rule.get_action(index):
            "draw_forward":
                var to = from + Vector2(0, length).rotated(deg2rad(rot))
                var line = Line2D.new()
                line.default_color = color
                line.width = width
                line.antialiased = true
                line.add_point(from)
                line.add_point(to)
                lines.push_back(line)
                from = to
            "rotate_right":
                rot += rule.angle
            "rotate_left":
                rot -= rule.angle
            "store":
                cache_queue.push_back([from, rot])
            "load":
                var cached_data = cache_queue.pop_back()
                from = cached_data[0]
                rot = cached_data[1]
    return lines


class Rule:
    var axiom
    var rules = {}
    var actions = {}
    var angle

    func _init(config=null):
        if config != null:
            self.axiom = config["axiom"]
            self.rules = config["rules"]
            self.actions = config["actions"]
            self.angle = config["angle"]

    func get_character(character):
        if rules.has(character):
            return rules.get(character)
        return character

    func get_action(character):
        return actions.get(character)
