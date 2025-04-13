//
//  TextureArray.hpp
//  metal_test
//
//  Created by Maria Chiara Monti on 13/04/2025.
//

#pragma once
#include <Metal/Metal.hpp>
#include <stb/stb_image.h>
#include <vector>

#include "VertexData.hpp"

enum TextureType {
    DIFFUSE,
    NORMAL,
    SPECULAR
};

class TextureArray {
public:
    TextureArray(std::vector<std::string>& diffuseFilePaths,
                 MTL::Device* metalDevice);
    ~TextureArray();
    
    void loadTextures(std::vector<std::string>& filePaths,
                      TextureType type);
    
    MTL::Texture* diffuseTextureArray;
    //Vectors to store texture info for each texture type
    std::vector<TextureInfo> diffuseTextureInfos;
    
private:
    MTL::Device* device;
};
