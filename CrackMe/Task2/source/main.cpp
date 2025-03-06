#include "CrackMe.hpp"

int main() {

	srand(uint(time(NULL)));

	RenderWindow window = {};
	window.create(VideoMode(MODE_WIDTH, MODE_HEIGHT), "TGF CrackYou");

	Font unispace = {};
	if (!unispace.loadFromFile(UNISPACE))
		return CRACKME_FONT_LOAD_ERROR;

	Text main_block_title = {};
	main_block_title.setFont(unispace);

	main_block_title.setString(MAIN_BLOCK_TITLE);
	main_block_title.setCharacterSize(MAIN_BLOCK_TITLE_SIZE);
	main_block_title.setFillColor(Color(_MAIN_BLOCK_TITLE_COLOR_));
	main_block_title.setPosition(Vector2f(MAIN_BLOCK_TITLE_X, MAIN_BLOCK_TITLE_Y));

	Texture background_texture = {};
	if (!background_texture.loadFromFile(BACKGROUND))
		return CRACKME_ING_LOAD_ERROR;

	IntRect background_rectangle({0, 0}, {MODE_WIDTH, MODE_HEIGHT});
	Sprite background(background_texture, background_rectangle);

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

				default:
					break;
			}
        }

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
        window.display();
    }


	return 0;
}
