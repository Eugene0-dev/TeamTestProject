shader_type spatial;
// Мы используем render_mode, чтобы отключить запись глубины и рисовать поверх,
// но при этом сохранять отбрасывание теней
render_mode unshaded, depth_test_disabled, blend_mix;

// Настройки контура
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform vec4 outline_color : source_color = vec4(0.0, 1.0, 1.0, 1.0); // По умолчанию бирюзовый
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;

// Текстура спрайта
uniform sampler2D texture_albedo : source_color, filter_nearest;

void vertex() {
	// Мы ничего не меняем в геометрии, но нам нужно передать UV во фрагмент
}

void fragment() {
	// --- ПРОХОД 1: РИСУЕМ САМ СПРАЙТ ---
	// Сначала берем цвет и альфа-канал самого спрайта
	vec4 albedo_tex = texture(texture_albedo, UV);
	
	// Если мы не перекрыты, мы рисуем обычный спрайт
	ALBEDO = albedo_tex.rgb;
	ALPHA = albedo_tex.a;
	
	// --- ПРОХОД 2: МАГИЯ ГЛУБИНЫ И КОНТУРА ---
	// Нам нужно знать, насколько далеко от нас находятся препятствия.
	// Для этого берем информацию из текстуры глубины сцены.
	float depth_tex = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	
	// Преобразуем глубину сцены в нормальное расстояние (camera_z)
	float scene_depth = FRAGCOORD.z; // Глубина текущего пикселя спрайта
	
	// Магия сравнения: если текущий пиксель спрайта находится ДАЛЬШЕ (больше Z),
	// чем пиксель сцены, значит мы перекрыты!
	if (scene_depth > depth_tex + 0.001) { // Добавляем микро-отступ для надежности
		
		// Мы перекрыты, значит теперь мы рисуем контур.
		// Логика контура: мы проверяем прозрачность соседних пикселей альфа-канала.
		vec2 size = vec2(outline_width);
		float total_alpha = albedo_tex.a;
		
		// Проверяем 4 соседних пикселя "крестом"
		total_alpha += texture(texture_albedo, UV + vec2(0.0, -size.y)).a;
		total_alpha += texture(texture_albedo, UV + vec2(0.0, size.y)).a;
		total_alpha += texture(texture_albedo, UV + vec2(-size.x, 0.0)).a;
		total_alpha += texture(texture_albedo, UV + vec2(size.x, 0.0)).a;
		
		// Если сам пиксель прозрачный, но рядом есть текстура — рисуем контур
		if (albedo_tex.a == 0.0 && total_alpha > 0.0) {
			ALBEDO = outline_color.rgb;
			ALPHA = outline_color.a;
		} else {
			// Мы перекрыты, но мы внутри предмета, а не на краю.
			// Скрываем внутренности, оставляя только контур.
			ALPHA = 0.0;
		}
	}
}