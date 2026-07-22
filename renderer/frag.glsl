#version 330 core
in vec2 vTexCoord;
out vec4 FragColor;
uniform sampler2D tex;
uniform vec4 uv_rect;

void main() {
    vec2 uv = vec2(
        uv_rect.x + vTexCoord.x * uv_rect.z,
        uv_rect.y + vTexCoord.y * uv_rect.w
    );
    FragColor = texture(tex, uv);
}
