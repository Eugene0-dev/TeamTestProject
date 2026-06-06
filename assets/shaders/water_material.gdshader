shader_type canvas_item;

uniform vec4 water_color : source_color = vec4(0.2, 0.5, 0.9, 0.6);
uniform float speed : hint_range(0.0, 10.0) = 1.5;

uniform float scale_x : hint_range(0.01, 2.0) = 0.12;
uniform float scale_y : hint_range(0.01, 2.0) = 0.35;

uniform float pixel_size : hint_range(1.0, 32.0) = 4.0;

varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    vec2 pixel_world_pos = floor(world_pos / pixel_size) * pixel_size;
    
    float t = TIME * speed;
    
    float cx = pixel_world_pos.x * scale_x;
    float cy = pixel_world_pos.y * scale_y;
    
    // 1. Первый слой волн: идет в одну сторону
    float wave1 = sin(cx + t) + cos(cy + t * 0.4);
    
    // 2. Второй слой: идет под углом, с другой частотой и чуть быстрее
    // Сдвиг "cx * 0.7 - cy * 1.3" ломает параллельные ряды
    float wave2 = sin(cx * 0.7 - cy * 1.3 + t * 1.3) * 0.8;
    
    // 3. Третий слой: мелкомасштабный хаос, который "рвет" длинные линии
    float micro_noise = sin(cx * 2.1 + cy * 1.7 - t * 0.8) * 0.4;
    
    // Смешиваем всё вместе
    float noise = (wave1 + wave2 + micro_noise) / 2.2;
    
    // Порог для бликов и теней
    vec4 final_color = water_color;
    if (noise > 0.6) {
        final_color.rgb += 0.15; // Блики
    } else if (noise < -0.65) {
        final_color.rgb -= 0.05; // Тени
    }
    
    COLOR = final_color;
}