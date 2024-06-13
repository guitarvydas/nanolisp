def main ():
    arg_array = parse_command_line_args ()
    root_project = arg_array [0] 
    root_0D = arg_array [1]
    arg = arg_array [2]
    main_container_name = arg_array [3]
    diagram_names = arg_array [4]
    palette = initialize_component_palette (root_project, root_0D, diagram_names, components_to_include_in_project)
    run (palette, root_project, root_0D, arg, main_container_name, diagram_names, start_function,
              show_hierarchy=False, show_connections=False, show_traces=False, show_all_outputs=False)

def start_function (root_project, root_0D, arg, main_container):
    source = new_datum_string (f'{arg}.scn')
    srcmsg = make_message("", source)
    inject (main_container, srcmsg)
    grammar = new_datum_string (f'{arg}.ohm')
    gmsg = make_message("grammar", grammar)
    inject (main_container, gmsg)


## Leaf components for this project...
def components_to_include_in_project (root_project, root_0D, reg):
    register_component (reg, Template (name = "Decode", instantiator = decode))



import urllib.parse
def decode_handler (eh, msg):
    # Decode a string using Python's equivalent of decodeURIComponent
    r1 = urllib.parse.unquote(msg.datum.srepr ())
    r2 = r1.replace('❳❲', ' ').replace('❲', '').replace('❳', '')
    send_string (eh, "", r2, msg)
def decode (reg, owner, name, template_data):
    name_with_id = gensym ("Decode")
    return make_leaf (name_with_id, owner, None, decode_handler)


main ()
