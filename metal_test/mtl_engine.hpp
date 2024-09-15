#pragma once

#define GLFW_INCLUDE_NONE
#import <GLFW/glfw3.h>
#define GLFW_EXPOSE_NATIVE_COCOA
#import <GLFW/glfw3native.h>

#include <Metal/Metal.hpp>
#include <Metal/Metal.h>
#include <QuartzCore/CAMetalLayer.hpp>
#include <QuartzCore/CAMetalLayer.h>
#include <QuartzCore/QuartzCore.hpp>

#include <simd/simd.h>
#include "VertexData.hpp"
#include "texture.hpp"
#include <stb/stb_image.h>
#include <filesystem>
#include "AAPLMathUtilities.h"

class MTLEngine {
public:
    void init();
    void run();
    void cleanup();
    
private:
    void initDevice();
    void initWindow();
    
    void createSquare();
    void createTriangle();
    void createCube();
    void createBuffers();
    
    void createDefaultLibrary();
    void createCommandQueue();
    void createRenderPipeline();
    
    void createDepthAndMSAATextures();
    void createRenderPassDescriptor();
    
    void updateRenderPassDescriptor();
    
    void encodeRenderCommand(MTL::RenderCommandEncoder* renderEncoder);
    void sendRenderCommand();
    void draw();
    
    static void frameBufferSizeCallback(GLFWwindow *window, int width, int height);
    void resizeFrameBuffer(int width, int height);
    
    MTL::Device* metalDevice;
    GLFWwindow* glfwWindow;
    NSWindow* metalWindow;
    CAMetalLayer* metalLayer;
    CA::MetalDrawable* metalDrawable;
    
    MTL::Library* metalDefaultLibrary;
    MTL::CommandQueue* metalCommandQueue;
    MTL::CommandBuffer* metalCommandBuffer;
    MTL::RenderPipelineState* metalRenderPS0;
    MTL::Buffer* triangleVertexBuffer;
    MTL::Buffer* squareVertexBuffer;
    MTL::Buffer* cubeVertexBuffer;
    MTL::Buffer* transformationBuffer;
    
    Texture* grassTexture;
    
    MTL::DepthStencilState* depthStencilState;
    MTL::RenderPassDescriptor* renderPassDescriptor;
    MTL::Texture* msaaRenderTargetTexture = nullptr;
    MTL::Texture* depthTexture;
    int sampleCount = 4;
};
