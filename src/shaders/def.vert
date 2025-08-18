#version 460 core

layout(location = 0) in vec3 aPos;  
layout(location = 1) in vec3 aColor;

out vec3 vColor;

uniform mat4 u_projection;
uniform mat4 u_view;
uniform mat4 u_model;

void main() {
    gl_Position = vec4(aPos, 1.0);
    vColor = aColor;
}
