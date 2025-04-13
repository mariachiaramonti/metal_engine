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
#include "TextureArray.hpp"
//#include "texture.hpp"
#include <stb/stb_image.h>
#include "AAPLMathUtilities.h"
#include "mesh.hpp"

#include <iostream>
#include <filesystem>

class MTLEngine {
public:
    void init();
    void run();
    void cleanup();
    
private:
    void initDevice();
    void initWindow();
    
    void loadMeshes();
    
    void createSphere(int numLatitudeLines=34, int numLongitudeLines=34);
    void createSquare();
    void createTriangle();
    void createCube();
    
    void createLight();
    
    void createBuffers();
    
    void createDefaultLibrary();
    void createCommandQueue();
    void createRenderPipeline();
    void createLightSourceRenderPipeline();
    
    void createDepthAndMSAATextures();
    void createRenderPassDescriptor();
    void updateRenderPassDescriptor();
    
    void draw();
    void sendRenderCommand();
    void encodeRenderCommand(MTL::RenderCommandEncoder* renderEncoder);
    
    static void frameBufferSizeCallback(GLFWwindow *window, int width, int height);
    void resizeFrameBuffer(int width, int height);
    
    MTL::Device* metalDevice;
    GLFWwindow* glfwWindow;
    NSWindow* metalWindow;
    CAMetalLayer* metalLayer;
    CA::MetalDrawable* metalDrawable;
    bool windowResizeFlag = false;
    int newWidth, newHeight;
    
    MTL::Library* metalDefaultLibrary;
    MTL::CommandQueue* metalCommandQueue;
    MTL::CommandBuffer* metalCommandBuffer;
    MTL::RenderPipelineState* metalRenderPS0;
    MTL::RenderPipelineState* metalLightSourceRenderPS0;
    MTL::RenderPassDescriptor* renderPassDescriptor;
    
    Mesh* mesh;
    
    MTL::Buffer* sphereVertexBuffer;
    MTL::Buffer* lightVertexBuffer;
    MTL::Buffer* sphereTransformationBuffer;
    MTL::Buffer* lightTransformationBuffer;
    MTL::Buffer* triangleVertexBuffer;
    MTL::Buffer* squareVertexBuffer;
    MTL::Buffer* cubeVertexBuffer;
    MTL::Buffer* transformationBuffer;
    
    MTL::DepthStencilState* depthStencilState;
    MTL::Texture* msaaRenderTargetTexture = nullptr;
    MTL::Texture* depthTexture;
    int sampleCount = 4;
    NS::UInteger vertexCount = 0;
    
    Texture* grassTexture;
};
