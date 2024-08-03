//
//  main.cpp
//  metal_test
//
//  Created by Maria Chiara Monti on 03/08/2024.
//

#include <iostream>
#include <Metal/Metal.hpp>
#include "mtl_engine.hpp"

int main(int argc, const char * argv[]) {
    // insert code here...
    
    //MTL::Device* device = MTL::CreateSystemDefaultDevice();
    std::cout << "Hello, World!\n";
    
    MTLEngine engine;
    engine.init();
    engine.run();
    engine.cleanup();
    
    return 0;
}
