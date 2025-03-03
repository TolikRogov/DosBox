#include "CrackMe.hpp"
using namespace sf;

int main() {

	srand(uint(time(NULL)));

	RenderWindow window = {};
	window.create(VideoMode(MODE_WIDTH, MODE_HEIGHT), "TGF Keygen");

	RectangleShape top_block_shape(Vector2f(120.f, 50.f));
	top_block_shape.setFillColor(Color(0, 255, 0));
	top_block_shape.setPosition(Vector2f(0.0f, 0.0f));
	top_block_shape.setSize(Vector2f(float(MODE_WIDTH), float(MODE_HEIGHT / 100 * TOP_BLOCK_PERCENT_SIZE)));

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

				case Event::KeyPressed: {
					switch (event.key.scancode) {
						case Keyboard::Scancode::Enter: {
							top_block_shape.setFillColor(Color(Uint8(rand() % 255),
															   Uint8(rand() % 255),
															   Uint8(rand() % 255)));
							break;
						}

						default:
							break;
					}
				}

				default:
					break;
			}
        }

        window.clear();

		window.draw(top_block_shape);

        window.display();
    }


	return 0;
}
