#include "CrackMe.hpp"

int main() {

	srand(uint(time(NULL)));

	RenderWindow window = {};
	window.create(VideoMode(MODE_WIDTH, MODE_HEIGHT), "TGF Keygen");

	// RectangleShape main_block_shape(Vector2f(0.f, 0.f));
	// main_block_shape.setFillColor(Color(MAIN_BLOCK_COLOR));
	// main_block_shape.setPosition(Vector2f(0.0f, TOP_BLOCK_HEIGHT));
	// main_block_shape.setSize(Vector2f(float(MODE_WIDTH), float(MAIN_BLOCK_HEIGHT)));

	Texture background_texture = {};
	if (!background_texture.loadFromFile(""))
	Sprite background(background_texture);

	Font unispace = {};
	if (!unispace.loadFromFile(UNISPACE))
		return CRACKME_FONT_LOAD_ERROR;

	Text main_block_title = {};
	main_block_title.setFont(unispace);

	main_block_title.setString(MAIN_BLOCK_TITLE);
	main_block_title.setCharacterSize(MAIN_BLOCK_TITLE_SIZE);
	main_block_title.setFillColor(Color(255, 255, 255));
	main_block_title.setPosition(Vector2f(MAIN_BLOCK_TITLE_X, MAIN_BLOCK_TITLE_Y));

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

        window.clear();

		window.draw(main_block_shape);
		window.draw(main_block_title);

        window.display();
    }


	return 0;
}
