#include "CrackMe.hpp"

int main() {

	srand(uint(time(NULL)));

	// Create window
	RenderWindow window = {};
	window.create(VideoMode(MODE_WIDTH, MODE_HEIGHT), "TGF CrackYou");

	// upload font
	Font unispace = {};
	if (!unispace.loadFromFile(UNISPACE))
		return CRACKME_FONT_LOAD_ERROR;

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
		return CRACKME_IMG_LOAD_ERROR;

	IntRect background_rectangle({0, 0}, {MODE_WIDTH, MODE_HEIGHT});
	Sprite background(background_texture, background_rectangle);

	// Button properties
	Texture button_texture = {};
  	if (!button_texture.loadFromFile(BUTTON_HOVER_OFF))
    	return CRACKME_IMG_LOAD_ERROR;

	Sprite button_sprite = {};
 	button_sprite.setPosition(0.0f, 0.0f);
	button_sprite.setTexture(button_texture);
	button_sprite.setTextureRect(IntRect({0, 0}, {BUTTON_WIDTH, BUTTON_HEIGHT}));

	Clock clock;

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

					if (button_sprite.getGlobalBounds().contains(mousePosF))
						button_sprite.setColor(Color(250, 20, 20));
					else
						button_sprite.setColor(Color(255, 255, 255));

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
        window.display();
    }


	return 0;
}
