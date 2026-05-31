shader_type canvas_item;

uniform vec4 water_color : source_color = vec4(0.2, 0.5, 0.9, 0.6);
uniform float speed : hint_range(0.0, 10.0) = 2.0;
uniform float scale : hint_range(0.1, 10.0) = 1.0;

void fragment() {
    // 1. Получаем координаты в пикселях (чтобы блики двигались шагами)
    // TEXTURE_PIXEL_SIZE дает размер одного пикселя текстуры
    vec2 pixel_uv = floor(UV * 8.0) / 8.0; 
    
    // 2. Генерируем "псевдо-шум" через синусы
    // Это создает движущиеся пятна, которые выглядят как блики
    float movement = TIME * speed;
    float noise = sin(pixel_uv.x * 10.0 * scale + movement) + 
                  cos(pixel_uv.y * 10.0 * scale + movement * 0.5);
    
    // 3. Делаем резкий порог (Threshold), чтобы получить четкие пиксели
    // Если значение шума выше 1.2 — это блик (светлее), иначе — обычная вода
    vec4 final_color = water_color;
    if (noise > 1.3) {
        final_color.rgb += 0.15; // Делаем пиксель светлее
    } else if (noise < -1.3) {
        final_color.rgb -= 0.05; // Или чуть темнее для глубины
    }
    
    COLOR = final_color;
}