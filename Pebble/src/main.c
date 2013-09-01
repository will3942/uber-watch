#include "pebble_os.h"
#include "pebble_app.h"
#include "pebble_fonts.h"

#define MY_UUID { 0x90, 0x05, 0xE0, 0x6F, 0x77, 0x4D, 0x4A, 0x57, 0x8D, 0x38, 0x8A, 0x0B, 0x6A, 0x24, 0xED, 0x12 }
PBL_APP_INFO(MY_UUID,
             "Uber", "Defined Code Ltd",
             1, 0, /* App version */
             DEFAULT_MENU_ICON,
             APP_INFO_STANDARD_APP);

static Window places;
static Window window;

typedef struct {
	char street[50];
	char distance_away[50];
} UberCab;

typedef struct {
	char name[50];
} MenuItem;

typedef struct {
	MenuLayer layer;
	UberCab ubercabs[25];
	char menu_entries[25][25];
} MenuLib;

typedef struct {
	MenuLayer layer;
	MenuItem menuitems[25];
	char menu_entries[25][25];
} LocationLib;

static MenuLib menu_stack[1];
static LocationLib main_stack[1];
int menu_location;
int current_id = 0;
int current_main_id = 0;

void receive(DictionaryIterator *received, void *context);
void send_message(char *action, char *params);

//CAB MENU FUNCTIONS
void menu_item_selected_callback(struct MenuLayer *menu_layer, MenuIndex *cell_index, void *context) {
	MenuLib *menu = &menu_stack[0];
}
uint16_t mainMenu_get_num_rows_in_section(struct MenuLayer *menu_layer, uint16_t section_index, void *callback_context) {
	return current_id;
}
uint16_t mainMenu_get_num_sections(struct MenuLayer *menu_layer, void *callback_context) {
	return 1;
}
void mainMenu_draw_row(GContext *ctx, const Layer *cell_layer, MenuIndex *cell_index, void *callback_context) {
	MenuLib *menu = &menu_stack[0];
	menu_cell_basic_draw(ctx, cell_layer, menu->ubercabs[cell_index->row].street, menu->ubercabs[cell_index->row].distance_away, NULL);
}
void mainMenu_draw_header(GContext *ctx, const Layer *cell_layer, uint16_t section_index, void *callback_context) {
	menu_cell_basic_header_draw(ctx, cell_layer, "Uber Cabs");
}

//MAIN MENU FUNCTIONS
void pmenu_item_selected_callback(struct MenuLayer *menu_layer, MenuIndex *cell_index, void *context) {
	LocationLib *pmenu = &main_stack[0];
	send_message("location", pmenu->menuitems[cell_index->row].name);

}
uint16_t pmainMenu_get_num_rows_in_section(struct MenuLayer *menu_layer, uint16_t section_index, void *callback_context) {
	return current_main_id;
}
uint16_t pmainMenu_get_num_sections(struct MenuLayer *menu_layer, void *callback_context) {
	return 1;
}
void pmainMenu_draw_row(GContext *ctx, const Layer *cell_layer, MenuIndex *cell_index, void *callback_context) {
	LocationLib *pmenu = &main_stack[0];
	menu_cell_basic_draw(ctx, cell_layer, pmenu->menuitems[cell_index->row].name, pmenu->menuitems[cell_index->row].name, NULL);
}
void pmainMenu_draw_header(GContext *ctx, const Layer *cell_layer, uint16_t section_index, void *callback_context) {
	menu_cell_basic_header_draw(ctx, cell_layer, "Select a location");
}

void send_message(char *action, char *params) {
	DictionaryIterator *iter;
	app_message_out_get(&iter);
	dict_write_cstring(iter, 0, action);
	dict_write_cstring(iter, 1, params);
	dict_write_end(iter);
	app_message_out_send();
	app_message_out_release();
	window_stack_push(&window, true);
}

void receive(DictionaryIterator *received, void *context) {
	char* action = dict_find(received, 0)->value->cstring;
	MenuLib *menu = &menu_stack[0];
	if (strcmp(action, (char*)"add_cab") == 0) {
		memset(&(menu->ubercabs[current_id].street), 0, 50);
		memset(&(menu->ubercabs[current_id].distance_away), 0, 50);
		memcpy(&(menu->ubercabs[current_id].street), dict_find(received, 1)->value->cstring, 49);
		memcpy(&(menu->ubercabs[current_id].distance_away), dict_find(received, 2)->value->cstring, 49);
		current_id ++;
	}
	else if (strcmp(action, (char*)"completed") == 0) {
		menu_layer_reload_data(&menu->layer);
	}
}

void addPlaces() {
	LocationLib *pmenu = &main_stack[0];
	memset(&(pmenu->menuitems[0].name), 0, 50);
	memcpy(&(pmenu->menuitems[0].name), "My Location", 49);
	memset(&(pmenu->menuitems[1].name), 0, 50);
	memcpy(&(pmenu->menuitems[1].name), "London (UK)", 49);
	memset(&(pmenu->menuitems[2].name), 0, 50);
	memcpy(&(pmenu->menuitems[2].name), "Atlanta", 49);
	memset(&(pmenu->menuitems[3].name), 0, 50);
	memcpy(&(pmenu->menuitems[3].name), "New York", 49);
	memset(&(pmenu->menuitems[4].name), 0, 50);
	memcpy(&(pmenu->menuitems[4].name), "Los Angeles", 49);
	memset(&(pmenu->menuitems[5].name), 0, 50);
	memcpy(&(pmenu->menuitems[5].name), "San Francisco", 49);
	memset(&(pmenu->menuitems[6].name), 0, 50);
	memcpy(&(pmenu->menuitems[6].name), "Shanghai", 49);
	current_main_id = 6;
	menu_layer_reload_data(&pmenu->layer);
}

MenuLayerCallbacks cbacks;

void handle_init(AppContextRef ctx) {
	resource_init_current_app(&APP_RESOURCES);
	window_init(&places, "Places Menu");
	window_init(&window, "Uber Pebble");
	window_set_fullscreen(&places, false);

	//INITIALIZE CABS MENU
	MenuLib *menu = &menu_stack[0];
	menu_layer_init(&menu->layer, GRect(0,0,window.layer.frame.size.w,window.layer.frame.size.h-15));
	menu_layer_set_click_config_onto_window(&menu->layer, &window);
	cbacks.get_num_sections = &mainMenu_get_num_sections;;
	cbacks.get_num_rows = &mainMenu_get_num_rows_in_section;
	cbacks.select_click = &menu_item_selected_callback;
	cbacks.draw_row = &mainMenu_draw_row;
	cbacks.draw_header = &mainMenu_draw_header;
	menu_layer_set_callbacks(&menu->layer, NULL, cbacks);
	layer_add_child(&window.layer, menu_layer_get_layer(&menu->layer));

    //INITIALIZE PLACES MENU
    LocationLib *pmenu = &main_stack[0];
	menu_layer_init(&pmenu->layer, GRect(0,0,places.layer.frame.size.w,places.layer.frame.size.h-15));
	menu_layer_set_click_config_onto_window(&pmenu->layer, &places);
	cbacks.get_num_sections = &pmainMenu_get_num_sections;;
	cbacks.get_num_rows = &pmainMenu_get_num_rows_in_section;
	cbacks.select_click = &pmenu_item_selected_callback;
	cbacks.draw_row = &pmainMenu_draw_row;
	cbacks.draw_header = &pmainMenu_draw_header;
	menu_layer_set_callbacks(&pmenu->layer, NULL, cbacks);
	layer_add_child(&places.layer, menu_layer_get_layer(&pmenu->layer));
	window_stack_push(&places, true);
	addPlaces();
}


void pbl_main(void *params) {
	PebbleAppHandlers handlers = {
		.init_handler = &handle_init,
		.messaging_info = {
			.buffer_sizes = {
				.inbound = 256,
				.outbound = 256,
			},
			.default_callbacks.callbacks = {
				.in_received = receive,
			},
		}
	};
	app_event_loop(params, &handlers);
}
