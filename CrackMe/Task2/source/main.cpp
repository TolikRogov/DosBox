#include "CrackMe.hpp"

int main() {
	CrackMeStatusCode crackme_status = CRACKME_NO_ERROR;

	// Create window
	RenderWindow window = {};
	window.create(VideoMode(MODE_WIDTH, MODE_HEIGHT), "TGF CrackYou");

	// upload font
	Font unispace = {};
	if (!unispace.loadFromFile(UNISPACE))
		CRACKME_ERROR_CHECK(CRACKME_FONT_LOAD_ERROR);

	// set font to main title
	Text main_block_title = {};
	main_block_title.setFont(unispace);

	// title properties
	main_block_title.setString(MAIN_BLOCK_TITLE);
	main_block_title.setCharacterSize(MAIN_BLOCK_TITLE_SIZE);
	main_block_title.setFillColor(Color(_MAIN_BLOCK_TITLE_COLOR_));
	main_block_title.setPosition(Vector2f(MAIN_BLOCK_TITLE_X, MAIN_BLOCK_TITLE_Y));

	// Background properties
	Texture background_texture = {};
	if (!background_texture.loadFromFile(BACKGROUND))
		CRACKME_ERROR_CHECK(CRACKME_IMG_LOAD_ERROR);

	IntRect background_rectangle({0, 0}, {MODE_WIDTH, MODE_HEIGHT});
	Sprite background(background_texture, background_rectangle);

	// Button properties
	Texture button_texture_hover_off = {};
  	if (!button_texture_hover_off.loadFromFile(BUTTON_HOVER_OFF))
    	CRACKME_ERROR_CHECK(CRACKME_IMG_LOAD_ERROR);

	Texture button_texture_hover_on = {};
	if (!button_texture_hover_on.loadFromFile(BUTTON_HOVER_ON))
    	CRACKME_ERROR_CHECK(CRACKME_IMG_LOAD_ERROR);

	Sprite button_sprite = {};
 	button_sprite.setPosition(BUTTON_X, BUTTON_Y);
	button_sprite.setTexture(button_texture_hover_off);
	button_sprite.setTextureRect(IntRect({0, 0}, {BUTTON_WIDTH, BUTTON_HEIGHT}));

	// Button text
	Text button_text = {};
	button_text.setFont(unispace);

	// title properties
	button_text.setString(BUTTON_TEXT);
	button_text.setCharacterSize(BUTTON_TEXT_SIZE);
	button_text.setFillColor(Color(_BUTTON_TEXT_COLOR_));
	button_text.setPosition(Vector2f(BUTTON_TEXT_X, BUTTON_TEXT_Y));

	// music
	SoundBuffer background_music = {};
	if (!background_music.loadFromFile(BG_MUSIC))
		CRACKME_ERROR_CHECK(CRACKME_MUSIC_LOAD_ERROR);

	Sound bg_sound = {};
	bg_sound.setBuffer(background_music);
	bg_sound.play();

	Clock clock;
	Hacking data = {COM_FILE, 0, NULL, NO_CRACK};
	Cracker cracker	= {&data, {{.name = "flag", .index = 0, .new_value = NEW_FLAG, .function = FindFlag},
							   {.name = "jump", .index = 0, .new_value = NEW_JUMP, .function = FindJump}}};

    while (window.isOpen())
    {
        Event event;
        while (window.pollEvent(event))
        {
			switch (event.type) {
				case Event::Closed: {
					window.close();
					break;
				}

				case Event::MouseMoved: {
					Vector2i mousePos = Mouse::getPosition(window);
					Vector2f mousePosF(static_cast<float>(mousePos.x), static_cast<float>(mousePos.y));

					if (button_sprite.getGlobalBounds().contains(mousePosF)) {
						button_sprite.setTexture(button_texture_hover_on);
						button_text.setFillColor(Color(_BUTTON_TEXT_COLOR_HOVER_));
					}
					else {
						button_sprite.setTexture(button_texture_hover_off);
						button_text.setFillColor(Color(_BUTTON_TEXT_COLOR_));
					}

					break;
				}

				case Event::MouseButtonPressed: {
					Vector2i mousePos = Mouse::getPosition(window);
					Vector2f mousePosF(static_cast<float>(mousePos.x), static_cast<float>(mousePos.y));
					if (button_sprite.getGlobalBounds().contains(mousePosF)) {
						crackme_status = RunCrack(&cracker);
						CRACKME_ERROR_MESSAGE(crackme_status);
					}
					break;
				}

				default:
					break;
			}
        }

		window.setSize({MODE_WIDTH, MODE_HEIGHT});

		if (clock.getElapsedTime().asMilliseconds() > TIME_TO_UPDATE) {
			if (background_rectangle.left + int(MODE_WIDTH) == BACKGROUND_FRAMES)
				background_rectangle.left = 0;
			else
				background_rectangle.left += MODE_WIDTH;

			background.setTextureRect(background_rectangle);
			clock.restart();
		}

        window.clear();
		window.draw(background);
		window.draw(main_block_title);
		window.draw(button_sprite);
		window.draw(button_text);
        window.display();
    }


	return 0;
}
