//
//  SyphonServerDrawingCoreProfile.m
//  Draws frame texture in the core profile mode
//
//  Originally created by Eduardo Roman on 1/26/15.
//  Modified by Keijiro Takahashi
//

#import "SyphonServerDrawingCoreProfile.h"
#import "SyphonOpenGLFunctions.h"
#import "SyphonProgram.h"
#import <OpenGL/gl3.h>

@implementation SyphonServerDrawingCoreProfile
{
    SyphonProgram* _syphonProgram;
    BOOL _initialized;
    GLuint _vao;
    GLuint _vbo;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _syphonProgram = [[SyphonProgram alloc] init];
        if (_syphonProgram == nil) self = nil;
    }
    return self;
}

- (void)setupWithContext:(CGLContextObj)context
{
    // Is the context with core profile?
    BOOL isCore = SyphonOpenGLContextIsCoreProfile(context);
    
    // Create a VAO when under core profile.
    if (isCore)
    {
        glGenVertexArrays(1, &_vao);
        glBindVertexArray(_vao);
    }
    
    // Create a VBO with a quad.
    glGenBuffers(1, &_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    
    static const float varray[] = {0, 0, 1, 0, 0, 1, 1, 1};
    glBufferData(GL_ARRAY_BUFFER, 4 * 2 * sizeof(GLfloat), varray, GL_STATIC_DRAW);
    
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(0);
    
    _initialized = YES;
}

- (void)drawFrameTexture:(GLuint)texID textureTarget:(GLenum)target imageRegion:(NSRect)region textureDimensions:(NSSize)size surfaceSize:(NSSize)surfaceSize flipped:(BOOL)isFlipped inContex:(CGLContextObj)context discardAlpha:(BOOL)discardAlpha
{
    // Initialize with the GL context if not yet.
    if (!_initialized) [self setupWithContext:context];
    
    // Swap the GL context.
    CGLContextObj prev_context = CGLGetCurrentContext();
    CGLSetCurrentContext(context);
    
    // Set up the program.
    _syphonProgram.discardAlpha = discardAlpha;
    [_syphonProgram use];
    
    // Use the VAO or rebind the VBO.
    if (_vao)
    {
        glBindVertexArray(_vao);
    }
    else
    {
        glBindBuffer(GL_ARRAY_BUFFER, _vbo);
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
        glEnableVertexAttribArray(0);
    }
    
    // Set up the other states.
    glViewport(0, 0, surfaceSize.width, surfaceSize.height);
    glDisable(GL_BLEND);
    glDisable(GL_CULL_FACE);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(target, texID);
    
    // Draw the quad.
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // Return to the previous context.
    CGLSetCurrentContext(prev_context);
}

@end
