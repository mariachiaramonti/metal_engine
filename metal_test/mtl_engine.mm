#include "mtl_engine.hpp"

void MTLEngine::init(){
    initDevice();
    initWindow();
    
    //createTriangle();
    //createSquare();
    //createCube();
    //createSphere();
    //createLight();
    loadMeshes();
    
    createBuffers();
    createDefaultLibrary();
    createCommandQueue();
    createRenderPipeline();
    createLightSourceRenderPipeline();
    createDepthAndMSAATextures();
    createRenderPassDescriptor();
}

void MTLEngine::run(){
    while(!glfwWindowShouldClose(glfwWindow))
    {
        @autoreleasepool {
            metalDrawable = (__bridge CA::MetalDrawable*)[metalLayer nextDrawable];
            draw();
        }
        glfwPollEvents();
    }
}

void MTLEngine::cleanup(){
    glfwTerminate();
    delete mesh;
    //transformationBuffer->release();
    //sphereTransformationBuffer->release();
    //lightTransformationBuffer->release();
    msaaRenderTargetTexture->release();
    depthTexture->release();
    renderPassDescriptor->release();
    metalDevice->release();
    //delete grassTexture;
}

void MTLEngine::initDevice(){
    metalDevice = MTL::CreateSystemDefaultDevice();
}

void MTLEngine::frameBufferSizeCallback(GLFWwindow *window, int width, int height)
{
    MTLEngine* engine = (MTLEngine*)glfwGetWindowUserPointer(window);
    engine->resizeFrameBuffer(width, height);
}

void MTLEngine::resizeFrameBuffer(int width, int height)
{
    metalLayer.drawableSize = CGSizeMake(width, height);
    // Deallocate the textures if they have been created
    if(msaaRenderTargetTexture)
    {
        msaaRenderTargetTexture->release();
        msaaRenderTargetTexture = nullptr;
    }
    if(depthTexture)
    {
        depthTexture->release();
        depthTexture = nullptr;
    }
    createDepthAndMSAATextures();
    metalDrawable = (__bridge CA::MetalDrawable*)[metalLayer nextDrawable];
    updateRenderPassDescriptor();
}

void MTLEngine::initWindow(){
    glfwInit();
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    glfwWindow = glfwCreateWindow(800, 600, "Metal Engine", NULL, NULL);
    if(!glfwWindow)
    {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    
    glfwSetWindowUserPointer(glfwWindow, this);
    glfwSetFramebufferSizeCallback(glfwWindow, frameBufferSizeCallback);
    int width, height;
    glfwGetFramebufferSize(glfwWindow, &width, &height);
    
    metalWindow = glfwGetCocoaWindow(glfwWindow);
    metalLayer =  [CAMetalLayer layer];
    metalLayer.device = (__bridge id<MTLDevice>)metalDevice;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    metalLayer.drawableSize = CGSizeMake(width, height);
    metalWindow.contentView.layer = metalLayer;
    metalWindow.contentView.wantsLayer = YES;
    
    metalDrawable = (__bridge CA::MetalDrawable*)[metalLayer nextDrawable];
    
}

void MTLEngine::loadMeshes()
{
    mesh = new Mesh("assets/SMG/smg.obj", metalDevice);
    
    VertexData lightSource[] = {
            // Front face               // Normals
             {{ 0.5, -0.5, -0.5, 1.0f}, {0.0, 0.0,-1.0, 1.0}},// bottom-right 2
             {{ 0.5,  0.5, -0.5, 1.0f}, {0.0, 0.0,-1.0, 1.0}},// top-right    3
             {{-0.5,  0.5, -0.5, 1.0f}, {0.0, 0.0,-1.0, 1.0}},// top-left     1
             {{ 0.5, -0.5, -0.5, 1.0f}, {0.0, 0.0,-1.0, 1.0}},// bottom-right 2
             {{-0.5,  0.5, -0.5, 1.0f}, {0.0, 0.0,-1.0, 1.0}},// top-left     1
             {{-0.5, -0.5, -0.5, 1.0f}, {0.0, 0.0,-1.0, 1.0}},// bottom-left  0
            // Right face
             {{ 0.5, -0.5,  0.5, 1.0f}, {1.0, 0.0, 0.0, 1.0}}, // bottom-right 6
             {{ 0.5,  0.5,  0.5, 1.0f}, {1.0, 0.0, 0.0, 1.0}}, // top-right    7
             {{ 0.5,  0.5, -0.5, 1.0f}, {1.0, 0.0, 0.0, 1.0}}, // top-right    3
             {{ 0.5, -0.5,  0.5, 1.0f}, {1.0, 0.0, 0.0, 1.0}}, // bottom-right 6
             {{ 0.5,  0.5, -0.5, 1.0f}, {1.0, 0.0, 0.0, 1.0}}, // top-right    3
             {{ 0.5, -0.5, -0.5, 1.0f}, {1.0, 0.0, 0.0, 1.0}}, // bottom-right 2
            // Back face
             {{-0.5, -0.5,  0.5, 1.0f}, {0.0, 0.0, 1.0, 1.0}}, // bottom-left  4
             {{-0.5,  0.5,  0.5, 1.0f}, {0.0, 0.0, 1.0, 1.0}}, // top-left     5
             {{ 0.5,  0.5,  0.5, 1.0f}, {0.0, 0.0, 1.0, 1.0}}, // top-right    7
             {{-0.5, -0.5,  0.5, 1.0f}, {0.0, 0.0, 1.0, 1.0}}, // bottom-left  4
             {{ 0.5,  0.5,  0.5, 1.0f}, {0.0, 0.0, 1.0, 1.0}}, // top-right    7
             {{ 0.5, -0.5,  0.5, 1.0f}, {0.0, 0.0, 1.0, 1.0}}, // bottom-right 6
            // Left face
             {{-0.5, -0.5, -0.5, 1.0f}, {-1.0, 0.0, 0.0, 1.0}}, // bottom-left  0
             {{-0.5,  0.5, -0.5, 1.0f}, {-1.0, 0.0, 0.0, 1.0}}, // top-left     1
             {{-0.5,  0.5,  0.5, 1.0f}, {-1.0, 0.0, 0.0, 1.0}}, // top-left     5
             {{-0.5, -0.5, -0.5, 1.0f}, {-1.0, 0.0, 0.0, 1.0}}, // bottom-left  0
             {{-0.5,  0.5,  0.5, 1.0f}, {-1.0, 0.0, 0.0, 1.0}}, // top-left     5
             {{-0.5, -0.5,  0.5, 1.0f}, {-1.0, 0.0, 0.0, 1.0}}, // bottom-left  4
            // Top face
             {{-0.5,  0.5,  0.5, 1.0f}, {0.0, 1.0, 0.0, 1.0}}, // top-left     5
             {{-0.5,  0.5, -0.5, 1.0f}, {0.0, 1.0, 0.0, 1.0}}, // top-left     1
             {{ 0.5,  0.5, -0.5, 1.0f}, {0.0, 1.0, 0.0, 1.0}}, // top-right    3
             {{-0.5,  0.5,  0.5, 1.0f}, {0.0, 1.0, 0.0, 1.0}}, // top-left     5
             {{ 0.5,  0.5, -0.5, 1.0f}, {0.0, 1.0, 0.0, 1.0}}, // top-right    3
             {{ 0.5,  0.5,  0.5, 1.0f}, {0.0, 1.0, 0.0, 1.0}}, // top-right    7
            // Bottom face
             {{-0.5, -0.5, -0.5, 1.0f}, {0.0, -1.0, 0.0, 1.0}}, // bottom-left  0
             {{-0.5, -0.5,  0.5, 1.0f}, {0.0, -1.0, 0.0, 1.0}}, // bottom-left  4
             {{ 0.5, -0.5,  0.5, 1.0f}, {0.0, -1.0, 0.0, 1.0}}, // bottom-right 6
             {{-0.5, -0.5, -0.5, 1.0f}, {0.0, -1.0, 0.0, 1.0}}, // bottom-left  0
             {{ 0.5, -0.5,  0.5, 1.0f}, {0.0, -1.0, 0.0, 1.0}}, // bottom-right 6
             {{ 0.5, -0.5, -0.5, 1.0f}, {0.0, -1.0, 0.0, 1.0}}  // bottom-right 2
        };
    
    lightVertexBuffer = metalDevice->newBuffer(&lightSource, sizeof(lightSource), MTL::ResourceStorageModeShared);
}

void MTLEngine::createSphere(int numLatitutdeLines, int numLongitudeLines)
{
    std::vector<VertexData> vertices;
    const float PI = 3.14159265359f;
    
    for(int lat = 0; lat < numLatitutdeLines; ++lat)
    {
        for(int lon = 0; lon < numLongitudeLines; ++lon)
        {
            // Define the corners of the square
            std::array<simd::float4, 4> squareVertices;
            std::array<simd::float4, 4> normals;
            
            for(int i = 0; i < 4; ++i)
            {
                float theta = (lat + (i / 2)) * PI/numLatitutdeLines;
                float phi = (lon + (i % 2)) * 2 * PI / numLongitudeLines;
                float sinTheta = sinf(theta);
                float cosTheta = cosf(theta);
                float sinPhi = sinf(phi);
                float cosPhi = cosf(phi);
                
                squareVertices[i] = {cosPhi * sinTheta, cosTheta, sinPhi * sinTheta, 1.0f};
                
                // Normal of the vertex, same as its position on a unit sphere
                normals[i] = simd::normalize(squareVertices[i]);
            }
            
            // Create two triangles for the square face with counter-clockwise winding order
            vertices.push_back(VertexData{squareVertices[0], normals[0]});
            vertices.push_back(VertexData{squareVertices[1], normals[1]});
            vertices.push_back(VertexData{squareVertices[2], normals[2]});
            
            vertices.push_back(VertexData{squareVertices[1], normals[1]});
            vertices.push_back(VertexData{squareVertices[3], normals[3]});
            vertices.push_back(VertexData{squareVertices[2], normals[2]});
        }
    }
    sphereVertexBuffer = metalDevice->newBuffer(vertices.data(), sizeof(VertexData) * vertices.size(), MTL::ResourceStorageModeShared);
    
    vertexCount = vertices.size();
}

void MTLEngine::createLight()
{
    // Cube for use in a right-handed coordinate system with triangle faces specified with a Counter-Clockwise winding order.
    VertexData lightSource[] = {
            // Front face            // Normals
            {{-0.5,-0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
            {{ 0.5,-0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
            {{ 0.5, 0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
            {{ 0.5, 0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
            {{-0.5, 0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
            {{-0.5,-0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
            
            // Back face
            {{ 0.5,-0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
            {{-0.5,-0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
            {{-0.5, 0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
            {{-0.5, 0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
            {{ 0.5, 0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
            {{ 0.5,-0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},

            // Top face
            {{-0.5, 0.5, 0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
            {{ 0.5, 0.5, 0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
            {{ 0.5, 0.5,-0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
            {{ 0.5, 0.5,-0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
            {{-0.5, 0.5,-0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
            {{-0.5, 0.5, 0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},

            // Bottom face
            {{-0.5,-0.5,-0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
            {{ 0.5,-0.5,-0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
            {{ 0.5,-0.5, 0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
            {{ 0.5,-0.5, 0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
            {{-0.5,-0.5, 0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
            {{-0.5,-0.5,-0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},

            // Left face
            {{-0.5,-0.5,-0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
            {{-0.5,-0.5, 0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
            {{-0.5, 0.5, 0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
            {{-0.5, 0.5, 0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
            {{-0.5, 0.5,-0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
            {{-0.5,-0.5,-0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},

            // Right face
            {{ 0.5,-0.5, 0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
            {{ 0.5,-0.5,-0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
            {{ 0.5, 0.5,-0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
            {{ 0.5, 0.5,-0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
            {{ 0.5, 0.5, 0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
            {{ 0.5,-0.5, 0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        };
    
    lightVertexBuffer = metalDevice->newBuffer(&lightSource, sizeof(lightSource), MTL::ResourceStorageModeShared);
}

void MTLEngine::createTriangle()
{
    simd::float3 triangleVertices[] = {
        {-0.5f, -0.5f, 0.0f},
        {0.5f, -0.5f, 0.0f},
        {0.0f, 0.5f, 0.0f}
    };
    
    triangleVertexBuffer = metalDevice->newBuffer(&triangleVertices, sizeof(triangleVertices), MTL::ResourceStorageModeShared);
}

void MTLEngine::createSquare()
{
    VertexData squareVertices[]
    {
        {{-0.5, -0.5, 0.5, 1.0f}, {0.0f, 0.0f}},
        {{-0.5, 0.5, 0.5, 1.0f}, {0.0f, 1.0f}},
        {{0.5, 0.5, 0.5, 1.0f}, {1.0f, 1.0f}},
        {{-0.5, -0.5, 0.5, 1.0f}, {0.0f, 0.0f}},
        {{0.5, 0.5, 0.5, 1.0f}, {1.0f, 1.0f}},
        {{0.5, -0.5, 0.5, 1.0}, {1.0, 0.0f}}
    };
    
    squareVertexBuffer = metalDevice->newBuffer(&squareVertices, sizeof(squareVertices), MTL::ResourceStorageModeShared);
    
    //grassTexture = new Texture("assets/mc_grass.jpeg", metalDevice);
}

void MTLEngine::createCube()
{
    // Cube for use in a right-handed coordinate system with triangle faces
        // specified with a Counter-Clockwise winding order.
    VertexData cubeVertices[] = {
            // Front face
            {{-0.5, -0.5, 0.5, 1.0}, {0.0, 0.0}},
            {{0.5, -0.5, 0.5, 1.0}, {1.0, 0.0}},
            {{0.5, 0.5, 0.5, 1.0}, {1.0, 1.0}},
            {{0.5, 0.5, 0.5, 1.0}, {1.0, 1.0}},
            {{-0.5, 0.5, 0.5, 1.0}, {0.0, 1.0}},
            {{-0.5, -0.5, 0.5, 1.0}, {0.0, 0.0}},

            // Back face
            {{0.5, -0.5, -0.5, 1.0}, {0.0, 0.0}},
            {{-0.5, -0.5, -0.5, 1.0}, {1.0, 0.0}},
            {{-0.5, 0.5, -0.5, 1.0}, {1.0, 1.0}},
            {{-0.5, 0.5, -0.5, 1.0}, {1.0, 1.0}},
            {{0.5, 0.5, -0.5, 1.0}, {0.0, 1.0}},
            {{0.5, -0.5, -0.5, 1.0}, {0.0, 0.0}},

            // Top face
            {{-0.5, 0.5, 0.5, 1.0}, {0.0, 0.0}},
            {{0.5, 0.5, 0.5, 1.0}, {1.0, 0.0}},
            {{0.5, 0.5, -0.5, 1.0}, {1.0, 1.0}},
            {{0.5, 0.5, -0.5, 1.0}, {1.0, 1.0}},
            {{-0.5, 0.5, -0.5, 1.0}, {0.0, 1.0}},
            {{-0.5, 0.5, 0.5, 1.0}, {0.0, 0.0}},

            // Bottom face
            {{-0.5, -0.5, -0.5, 1.0}, {0.0, 0.0}},
            {{0.5, -0.5, -0.5, 1.0}, {1.0, 0.0}},
            {{0.5, -0.5, 0.5, 1.0}, {1.0, 1.0}},
            {{0.5, -0.5, 0.5, 1.0}, {1.0, 1.0}},
            {{-0.5, -0.5, 0.5, 1.0}, {0.0, 1.0}},
            {{-0.5, -0.5, -0.5, 1.0}, {0.0, 0.0}},

            // Left face
            {{-0.5, -0.5, -0.5, 1.0}, {0.0, 0.0}},
            {{-0.5, -0.5, 0.5, 1.0}, {1.0, 0.0}},
            {{-0.5, 0.5, 0.5, 1.0}, {1.0, 1.0}},
            {{-0.5, 0.5, 0.5, 1.0}, {1.0, 1.0}},
            {{-0.5, 0.5, -0.5, 1.0}, {0.0, 1.0}},
            {{-0.5, -0.5, -0.5, 1.0}, {0.0, 0.0}},

            // Right face
            {{0.5, -0.5, 0.5, 1.0}, {0.0, 0.0}},
            {{0.5, -0.5, -0.5, 1.0}, {1.0, 0.0}},
            {{0.5, 0.5, -0.5, 1.0}, {1.0, 1.0}},
            {{0.5, 0.5, -0.5, 1.0}, {1.0, 1.0}},
            {{0.5, 0.5, 0.5, 1.0}, {0.0, 1.0}},
            {{0.5, -0.5, 0.5, 1.0}, {0.0, 0.0}},
        };
    
    cubeVertexBuffer = metalDevice->newBuffer(&cubeVertices, sizeof(cubeVertices), MTL::ResourceStorageModeShared);
    //transformationBuffer = metalDevice->newBuffer(sizeof(TransformationData), MTL::ResourceStorageModeShared);
    
//    grassTexture = new Texture("assets/halo_odst_microsoft_image.jpeg", metalDevice);
}

//void MTLEngine::createBuffers(){
//    transformationBuffer = metalDevice->newBuffer(sizeof(TransformationData), MTL::ResourceStorageModeShared);
//}

void MTLEngine::createBuffers(){
    sphereTransformationBuffer = metalDevice->newBuffer(sizeof(TransformationData), MTL::ResourceStorageModeShared);
    lightTransformationBuffer = metalDevice->newBuffer(sizeof(TransformationData), MTL::ResourceStorageModeShared);
}

void MTLEngine::createDefaultLibrary()
{
    metalDefaultLibrary = metalDevice->newDefaultLibrary();
    if(!metalDefaultLibrary)
    {
        std::cerr << "Failed to load default library";
        std::exit(-1);
    }
    
}

void MTLEngine::createCommandQueue()
{
    metalCommandQueue = metalDevice->newCommandQueue();
}

void MTLEngine::createRenderPipeline()
{
//    MTL::Function* vertexShader = metalDefaultLibrary->newFunction(NS::String::string("vertexShader", NS::ASCIIStringEncoding));
//    assert(vertexShader);
    
    //MTL::Function* vertexShader = metalDefaultLibrary->newFunction(NS::String::string("sphereVertexShader", NS::ASCIIStringEncoding));
    //assert(vertexShader);
                                                                   
//    MTL::Function* fragmentShader = metalDefaultLibrary->newFunction(NS::String::string("fragmentShader", NS::ASCIIStringEncoding));
//    assert(fragmentShader);
    
    //MTL::Function* fragmentShader = metalDefaultLibrary->newFunction(NS::String::string("sphereFragmentShader", NS::ASCIIStringEncoding));
    //assert(fragmentShader);
    
    MTL::Function* vertexShader = metalDefaultLibrary->newFunction(NS::String::string("vertexShader", NS::ASCIIStringEncoding));
    assert(vertexShader);
    
    MTL::Function* fragmentShader = metalDefaultLibrary->newFunction(NS::String::string("fragmentShader", NS::ASCIIStringEncoding));
    assert(fragmentShader);
    
    MTL::RenderPipelineDescriptor* renderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();

    renderPipelineDescriptor->setVertexFunction(vertexShader);
    renderPipelineDescriptor->setFragmentFunction(fragmentShader);
    assert(renderPipelineDescriptor);
    MTL::PixelFormat pixelFormat = (MTL::PixelFormat)metalLayer.pixelFormat;
    renderPipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(pixelFormat);
    renderPipelineDescriptor->setSampleCount(sampleCount);
    renderPipelineDescriptor->setLabel(NS::String::string("Model Render Pipeline", NS::ASCIIStringEncoding));
    renderPipelineDescriptor->setDepthAttachmentPixelFormat(MTL::PixelFormatDepth32Float);
    renderPipelineDescriptor->setTessellationOutputWindingOrder(MTL::WindingCounterClockwise);
    
    NS::Error* error;
    metalRenderPS0 = metalDevice->newRenderPipelineState(renderPipelineDescriptor, &error);
    
    if(metalRenderPS0 == nil)
    {
        std::cout << "Error creating render pipeline state: " << error << std::endl;
        std::exit(0);
    }
    
    MTL::DepthStencilDescriptor* depthStencilDescriptor = MTL::DepthStencilDescriptor::alloc()->init();
    depthStencilDescriptor->setDepthCompareFunction(MTL::CompareFunctionLessEqual);
    depthStencilDescriptor->setDepthWriteEnabled(true);
    depthStencilState = metalDevice->newDepthStencilState(depthStencilDescriptor);
    
    depthStencilDescriptor->release();
    renderPipelineDescriptor->release();
    vertexShader->release();
    fragmentShader->release();
}

void MTLEngine::createLightSourceRenderPipeline()
{
    MTL::Function* vertexShader = metalDefaultLibrary->newFunction(NS::String::string("lightVertexShader", NS::ASCIIStringEncoding));
    assert(vertexShader);
    MTL::Function* fragmentShader = metalDefaultLibrary->newFunction(NS::String::string("lightFragmentShader", NS::ASCIIStringEncoding));
    assert(fragmentShader);
    
    MTL::RenderPipelineDescriptor* renderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    renderPipelineDescriptor->setVertexFunction(vertexShader);
    renderPipelineDescriptor->setFragmentFunction(fragmentShader);
    assert(renderPipelineDescriptor);
    MTL::PixelFormat pixelFormat = (MTL::PixelFormat)metalLayer.pixelFormat;
    renderPipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(pixelFormat);
    renderPipelineDescriptor->setSampleCount(sampleCount);
    renderPipelineDescriptor->setLabel(NS::String::string("Light source render pipeline", NS::ASCIIStringEncoding));
    renderPipelineDescriptor->setDepthAttachmentPixelFormat(MTL::PixelFormatDepth32Float);
    renderPipelineDescriptor->setTessellationOutputWindingOrder(MTL::WindingCounterClockwise);
    
    NS::Error* error;
    metalLightSourceRenderPS0 = metalDevice->newRenderPipelineState(renderPipelineDescriptor, &error);
    
    renderPipelineDescriptor->release();
}

void MTLEngine::createDepthAndMSAATextures()
{
    MTL::TextureDescriptor* msaaTextureDescriptor = MTL::TextureDescriptor::alloc()->init();
    msaaTextureDescriptor->setTextureType(MTL::TextureType2DMultisample);
    msaaTextureDescriptor->setPixelFormat(MTL::PixelFormatBGRA8Unorm);
    msaaTextureDescriptor->setWidth(metalLayer.drawableSize.width);
    msaaTextureDescriptor->setHeight(metalLayer.drawableSize.height);
    msaaTextureDescriptor->setSampleCount(sampleCount);
    msaaTextureDescriptor->setUsage(MTL::TextureUsageRenderTarget);
    msaaTextureDescriptor->setStorageMode(MTL::StorageModePrivate); // to make it work on older device
    
    msaaRenderTargetTexture = metalDevice->newTexture(msaaTextureDescriptor);
    
    MTL::TextureDescriptor* depthTextureDescriptor = MTL::TextureDescriptor::alloc()->init();
    depthTextureDescriptor->setTextureType(MTL::TextureType2DMultisample);
    depthTextureDescriptor->setPixelFormat(MTL::PixelFormatDepth32Float);
    depthTextureDescriptor->setWidth(metalLayer.drawableSize.width);
    depthTextureDescriptor->setHeight(metalLayer.drawableSize.height);
    depthTextureDescriptor->setUsage(MTL::TextureUsageRenderTarget);
    depthTextureDescriptor->setSampleCount(sampleCount);
    depthTextureDescriptor->setStorageMode(MTL::StorageModePrivate); // to make it work on older device
    
    depthTexture = metalDevice->newTexture(depthTextureDescriptor);
    
    msaaTextureDescriptor->release();
    depthTextureDescriptor->release();
}

void MTLEngine::createRenderPassDescriptor()
{
    renderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
    
    MTL::RenderPassColorAttachmentDescriptor* colorAttachment = renderPassDescriptor->colorAttachments()->object(0);
    MTL::RenderPassDepthAttachmentDescriptor* depthAttachment = renderPassDescriptor->depthAttachment();
    
    colorAttachment->setTexture(msaaRenderTargetTexture);
    colorAttachment->setResolveTexture(metalDrawable->texture());
    colorAttachment->setLoadAction(MTL::LoadActionClear);
    colorAttachment->setClearColor(MTL::ClearColor(41.0f/255.0f, 42.0f/255.0f, 48.0f/255.0f, 1.0));
    colorAttachment->setStoreAction(MTL::StoreActionMultisampleResolve);
    
    depthAttachment->setTexture(depthTexture);
    depthAttachment->setLoadAction(MTL::LoadActionClear);
    depthAttachment->setStoreAction(MTL::StoreActionDontCare);
    depthAttachment->setClearDepth(1.0);
}

void MTLEngine::updateRenderPassDescriptor()
{
    renderPassDescriptor->colorAttachments()->object(0)->setTexture(msaaRenderTargetTexture);
    renderPassDescriptor->colorAttachments()->object(0)->setResolveTexture(metalDrawable->texture());
    renderPassDescriptor->depthAttachment()->setTexture(depthTexture);
}

void MTLEngine::draw()
{
    sendRenderCommand();
}

void MTLEngine::sendRenderCommand()
{
    metalCommandBuffer = metalCommandQueue->commandBuffer();
    
    updateRenderPassDescriptor();
    
    MTL::RenderCommandEncoder* renderCommandEncoder = metalCommandBuffer->renderCommandEncoder(renderPassDescriptor);
    encodeRenderCommand(renderCommandEncoder);
    renderCommandEncoder->endEncoding();
    
    metalCommandBuffer->presentDrawable(metalDrawable);
    metalCommandBuffer->commit();
    metalCommandBuffer->waitUntilCompleted();
    
    //renderPassDescriptor->release();
}

void MTLEngine::encodeRenderCommand(MTL::RenderCommandEncoder *renderCommandEncoder)
{
    renderCommandEncoder->setFrontFacingWinding(MTL::WindingCounterClockwise);
    renderCommandEncoder->setCullMode(MTL::CullModeBack);
    renderCommandEncoder->setRenderPipelineState(metalRenderPS0);
    renderCommandEncoder->setDepthStencilState(depthStencilState);
    renderCommandEncoder->setVertexBuffer(mesh->vertexBuffer, 0, 0);
    
    matrix_float4x4 rotationMatrix = matrix4x4_rotation(-125 * (M_PI / 180.0f), 0.0, 1.0, 0.0);
    matrix_float4x4 modelMatrix = matrix4x4_translation(0.0f, 0.0f, -3.2f) * rotationMatrix;
    
    float aspectRatio = (metalDrawable->layer()->drawableSize().width / metalDrawable->layer()->drawableSize().height);
    float fov = 45 * (M_PI / 180.f);
    float nearZ = 0.1f;
    float farZ = 100.f;
    
    matrix_float4x4 perspectiveMatrix = matrix_perspective_right_hand(fov, aspectRatio, nearZ, farZ);
    
    renderCommandEncoder->setVertexBytes(&modelMatrix, sizeof(modelMatrix), 1);
    renderCommandEncoder->setVertexBytes(&perspectiveMatrix, sizeof(perspectiveMatrix), 2);
    simd_float4 cubeColor = simd_make_float4(1.0, 1.0, 1.0, 1.0);
    simd_float4 lightColor = simd_make_float4(1.0, 1.0, 1.0, 1.0);
    renderCommandEncoder->setFragmentBytes(&cubeColor, sizeof(cubeColor), 0);
    renderCommandEncoder->setFragmentBytes(&lightColor, sizeof(lightColor), 1);
    simd_float4 lightPosition = simd_make_float4(2 * cos(glfwGetTime()), 0.6, -0.5, 1);
    renderCommandEncoder->setFragmentBytes(&lightPosition, sizeof(lightPosition), 2);
    renderCommandEncoder->setFragmentTexture(mesh->diffuseTextures, 3);
    renderCommandEncoder->setFragmentBuffer(mesh->diffuseTextureInfos, 0, 4);
    
    MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;
    renderCommandEncoder->drawIndexedPrimitives(typeTriangle, mesh->indexCount, MTL::IndexTypeUInt32, mesh->indexBuffer, 0);
    
    matrix_float4x4 scaleMatrix = matrix4x4_scale(0.3f, 0.3f, 0.3f);
    matrix_float4x4 translationMatrix = matrix4x4_translation(lightPosition.xyz);
    
    modelMatrix = matrix_identity_float4x4;
    modelMatrix = matrix_multiply(scaleMatrix, modelMatrix);
    modelMatrix = matrix_multiply(translationMatrix, modelMatrix);
    renderCommandEncoder->setFrontFacingWinding(MTL::WindingCounterClockwise);
    
    renderCommandEncoder->setRenderPipelineState(metalLightSourceRenderPS0);
    renderCommandEncoder->setVertexBuffer(lightVertexBuffer, 0, 0);
    renderCommandEncoder->setVertexBytes(&modelMatrix, sizeof(modelMatrix), 1);
    renderCommandEncoder->setVertexBytes(&perspectiveMatrix, sizeof(perspectiveMatrix), 2);
    typeTriangle = MTL::PrimitiveTypeTriangle;
    NS::UInteger vertexStart = 0;
    NS::UInteger vertexCount = 6 * 6;
    renderCommandEncoder->setFragmentBytes(&lightColor, sizeof(lightColor), 0);
    renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);
    

}

