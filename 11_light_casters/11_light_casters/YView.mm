//
//  YView.m
//  3
//
//  Created by wangkaiyu on 2018/11/26.
//  Copyright © 2018 wangkaiyu. All rights reserved.
//

#import "YView.h"
#import <OpenGLES/ES3/gl.h>
#import "utils.h"
#import <GLKit/GLKit.h>
#include "KYTexture.h"
#include "math3d.h"
#include <iostream>
#include "./timeutil.h"


@interface YView()
{
    CAEAGLLayer *_layer;
    EAGLContext *_cont;
    GLuint _renderBuffer,_depthRenderBuffer;
    GLuint _frameBuffer;
    
    GLuint _programY;
    GLuint _positionY;
    GLuint _texCoordY;
    GLuint _normalY;
    GLuint _tex;
    GLuint _tex1;
    GLuint _emission_tex;
    GLuint _direction;

    GLuint _m;
    GLuint _v;
    GLuint _p;
    GLuint _LprogramY;
    GLuint _LpositionY;
    GLuint _Lm;
    GLuint _Lv;
    GLuint _Lp;

    GLuint _amb;
    GLuint _diff;
    GLuint _spe;
    float _shine;
    GLuint _ambLight;
    GLuint _diffLight;
    GLuint _speLight;
    
    GLuint _fangxiang;
    GLuint _cutoff;

    GLuint _timodel;
}

@end


@implementation YView
float a = 0;
+(Class)layerClass
{
    return [CAEAGLLayer class];
}

-(instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupLayer];
        [self setupContext];
        [self setupDepthBuffer];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        [self setProgram];
        [self setLightProgram];
        [self setupDisplayLink];
    }
    return self;
}

-(void)setupLayer
{
    _layer = (CAEAGLLayer*)self.layer;
    _layer.opaque = YES;
}

-(void)loadtex{
    
}


-(void)setupContext
{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES3;
    _cont = [[EAGLContext alloc] initWithAPI:api];
    
    [EAGLContext setCurrentContext:_cont];
}

-(void)setupRenderBuffer
{
    glGenRenderbuffers(1, &(_renderBuffer));
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_COLOR_ATTACHMENT0, self.frame.size.width, self.frame.size.height);
    [_cont renderbufferStorage:GL_RENDERBUFFER fromDrawable:_layer];
}
- (void)setupDepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
//    [_cont renderbufferStorage:GL_RENDERBUFFER fromDrawable:_layer];

}
-(void)setupFrameBuffer
{
    glGenFramebuffers(1, &(_frameBuffer));
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);

}

-(void)setProgram
{
    NSString *ver = [[NSBundle mainBundle] pathForResource:@"ver" ofType:@"glsl"];
    NSString *frag = [[NSBundle mainBundle] pathForResource:@"frag" ofType:@"glsl"];
    
    GLuint vershader = [utils loadShader:GL_VERTEX_SHADER withpath:ver];
    GLuint fragshader = [utils loadShader:GL_FRAGMENT_SHADER withpath:frag];
    
    _programY = glCreateProgram();
    glAttachShader(_programY, vershader);
    glAttachShader(_programY, fragshader);
    glLinkProgram(_programY);
     //glUseProgram(_programY);
    _positionY = glGetAttribLocation(_programY, "Yposition");
    _normalY = glGetAttribLocation(_programY, "Onormal");
    _texCoordY = glGetAttribLocation(_programY, "texIoord");
//    _colorY = glGetAttribLocation(_programY, "Ycolor");
    //_mvp = glGetUniformLocation(_programY, "mvp");
    _m = glGetUniformLocation(_programY, "Model_M");
    _v = glGetUniformLocation(_programY, "View");
    _p = glGetUniformLocation(_programY, "Projection");
//    _objColor = glGetUniformLocation(_programY,"objectColor");
//    _lightColor = glGetUniformLocation(_programY,"lightColor");
    _emission_tex = glGetUniformLocation(_programY, "letter");
    _tex1 = glGetUniformLocation(_programY, "tex1");
    _amb = glGetUniformLocation(_programY, "amb");
    _diff = glGetUniformLocation(_programY, "diff");
    _spe = glGetUniformLocation(_programY, "spe");
    _shine = glGetUniformLocation(_programY, "shininess");
    
    _ambLight = glGetUniformLocation(_programY, "ambLight");
    _diffLight = glGetUniformLocation(_programY, "diffLight");
    _speLight = glGetUniformLocation(_programY, "speLight");
    
    _direction = glGetUniformLocation(_programY, "directionLight");
    
    _fangxiang = glGetUniformLocation(_programY, "fangxiang");
    _cutoff = glGetUniformLocation(_programY, "cutoff");
    
    _timodel = glGetUniformLocation(_programY, "timodel");
}

-(void)setLightProgram{
    NSString * lightV = [[NSBundle mainBundle] pathForResource:@"lightVer" ofType:@".glsl"];
    NSString * lightF = [[NSBundle mainBundle] pathForResource:@"lightfrag" ofType:@".glsl"];
    
    GLuint Lvershader = [utils loadShader:GL_VERTEX_SHADER withpath:lightV];
    GLuint Lfragshader = [utils loadShader:GL_FRAGMENT_SHADER withpath:lightF];
    _LprogramY = glCreateProgram();
    glAttachShader(_LprogramY, Lvershader);
    glAttachShader(_LprogramY, Lfragshader);
    glLinkProgram(_LprogramY);
    //glUseProgram(_LprogramY);
    _LpositionY = glGetAttribLocation(_LprogramY, "Yposition_L");
    _Lm = glGetUniformLocation(_LprogramY, "Model_M");
    _Lv = glGetUniformLocation(_LprogramY, "View");
    _Lp = glGetUniformLocation(_LprogramY, "Projection");
}

- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

//float redius = 10.0;
float redius_z = 0.0;


-(void)render:(CADisplayLink*)displayLink
{
    const char *path = [[[NSBundle mainBundle] pathForResource:@"container2" ofType:@".png"] UTF8String];
    GLuint texture0 = KYTexture::getTextureId(path);
    const char *path1 = [[[NSBundle mainBundle] pathForResource:@"container2_specular" ofType:@".png"] UTF8String];
    GLuint texture1 = KYTexture::getTextureId(path1);
    const char *emission_path = [[[NSBundle mainBundle] pathForResource:@"letter" ofType:@".jpg"] UTF8String];
    GLuint texture2 = KYTexture::getTextureId(emission_path);
    glClearColor(0.0, 0.0, 0., 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glEnable(GL_DEPTH_TEST);

    float points[] = {
        -0.5f, -0.5f, -0.5f,  0.0f,  0.0f, -1.0f,  0.0f, 0.0f,
        0.5f, -0.5f, -0.5f,  0.0f,  0.0f, -1.0f,  1.0f, 0.0f,
        0.5f,  0.5f, -0.5f,  0.0f,  0.0f, -1.0f,  1.0f, 1.0f,
        0.5f,  0.5f, -0.5f,  0.0f,  0.0f, -1.0f,  1.0f, 1.0f,
        -0.5f,  0.5f, -0.5f,  0.0f,  0.0f, -1.0f,  0.0f, 1.0f,
        -0.5f, -0.5f, -0.5f,  0.0f,  0.0f, -1.0f,  0.0f, 0.0f,
        
        -0.5f, -0.5f,  0.5f,  0.0f,  0.0f, 1.0f,   0.0f, 0.0f,
        0.5f, -0.5f,  0.5f,  0.0f,  0.0f, 1.0f,   1.0f, 0.0f,
        0.5f,  0.5f,  0.5f,  0.0f,  0.0f, 1.0f,   1.0f, 1.0f,
        0.5f,  0.5f,  0.5f,  0.0f,  0.0f, 1.0f,   1.0f, 1.0f,
        -0.5f,  0.5f,  0.5f,  0.0f,  0.0f, 1.0f,   0.0f, 1.0f,
        -0.5f, -0.5f,  0.5f,  0.0f,  0.0f, 1.0f,   0.0f, 0.0f,
        
        -0.5f,  0.5f,  0.5f, -1.0f,  0.0f,  0.0f,  1.0f, 0.0f,
        -0.5f,  0.5f, -0.5f, -1.0f,  0.0f,  0.0f,  1.0f, 1.0f,
        -0.5f, -0.5f, -0.5f, -1.0f,  0.0f,  0.0f,  0.0f, 1.0f,
        -0.5f, -0.5f, -0.5f, -1.0f,  0.0f,  0.0f,  0.0f, 1.0f,
        -0.5f, -0.5f,  0.5f, -1.0f,  0.0f,  0.0f,  0.0f, 0.0f,
        -0.5f,  0.5f,  0.5f, -1.0f,  0.0f,  0.0f,  1.0f, 0.0f,
        
        0.5f,  0.5f,  0.5f,  1.0f,  0.0f,  0.0f,  1.0f, 0.0f,
        0.5f,  0.5f, -0.5f,  1.0f,  0.0f,  0.0f,  1.0f, 1.0f,
        0.5f, -0.5f, -0.5f,  1.0f,  0.0f,  0.0f,  0.0f, 1.0f,
        0.5f, -0.5f, -0.5f,  1.0f,  0.0f,  0.0f,  0.0f, 1.0f,
        0.5f, -0.5f,  0.5f,  1.0f,  0.0f,  0.0f,  0.0f, 0.0f,
        0.5f,  0.5f,  0.5f,  1.0f,  0.0f,  0.0f,  1.0f, 0.0f,
        
        -0.5f, -0.5f, -0.5f,  0.0f, -1.0f,  0.0f,  0.0f, 1.0f,
        0.5f, -0.5f, -0.5f,  0.0f, -1.0f,  0.0f,  1.0f, 1.0f,
        0.5f, -0.5f,  0.5f,  0.0f, -1.0f,  0.0f,  1.0f, 0.0f,
        0.5f, -0.5f,  0.5f,  0.0f, -1.0f,  0.0f,  1.0f, 0.0f,
        -0.5f, -0.5f,  0.5f,  0.0f, -1.0f,  0.0f,  0.0f, 0.0f,
        -0.5f, -0.5f, -0.5f,  0.0f, -1.0f,  0.0f,  0.0f, 1.0f,
        
        -0.5f,  0.5f, -0.5f,  0.0f,  1.0f,  0.0f,  0.0f, 1.0f,
        0.5f,  0.5f, -0.5f,  0.0f,  1.0f,  0.0f,  1.0f, 1.0f,
        0.5f,  0.5f,  0.5f,  0.0f,  1.0f,  0.0f,  1.0f, 0.0f,
        0.5f,  0.5f,  0.5f,  0.0f,  1.0f,  0.0f,  1.0f, 0.0f,
        -0.5f,  0.5f,  0.5f,  0.0f,  1.0f,  0.0f,  0.0f, 0.0f,
        -0.5f,  0.5f, -0.5f,  0.0f,  1.0f,  0.0f,  0.0f, 1.0f
    };
    
    M3DMatrix44f mViewMatrix;

    M3DMatrix44f mProjection;
    m3dLoadIdentity44(mProjection);
    m3dMakePerspectiveMatrix(mProjection, 45.0 * 3.14 /180.0, 720.0/1280.0, 0.1, 100);

    M3DVector3f cameraPos;
    m3dLoadVector3(cameraPos, 0.0, 0.0, 3.0);
    M3DVector3f cameraTarget;
    m3dLoadVector3(cameraTarget, 0.0, 0.0, -1.0);
    M3DVector3f cameraUp;
    m3dLoadVector3(cameraUp, 0.0, 1.0, 0.0);
    
    M3DVector3f cameraDir;
    
    M3DVector3f temp_cv;
    m3dCopyVector3(temp_cv, cameraTarget);
    m3dNegateVector3(temp_cv);
    
    M3DVector3f n;
    m3dAddVectors3(n, cameraPos, temp_cv);
    m3dNormalizeVector3(n);
    
    M3DVector3f u; // right
    m3dCrossProduct3(u, cameraUp, n);
    m3dNormalizeVector3(u);
    
    M3DVector3f v; // up
    m3dCrossProduct3(v, n, u);
    
    M3DVector3f temp_u;
    m3dCopyVector3(temp_u, u);
    m3dNegateVector3(temp_u);
    
    M3DVector3f temp_v;
    m3dCopyVector3(temp_v, v);
    m3dNegateVector3(temp_v);
    
    M3DVector3f temp_n;
    m3dCopyVector3(temp_n, n);
    m3dNegateVector3(temp_n);
    
    M3DMatrix44f matrix = { u[0], v[0], n[0], 0.0f,
        u[1], v[1], n[1], 0.0f,
        u[2], v[2], n[2], 0.0f,
        m3dDotProduct3(temp_u, cameraPos), m3dDotProduct3(temp_v, cameraPos), m3dDotProduct3(temp_n, cameraPos), 1.0f};
    
    m3dCopyMatrix44(mViewMatrix, matrix);

    GLuint VBO;
    GLuint VAO;
    GLuint lightVAO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW);
    
    glGenVertexArrays(1, &VAO);
    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glVertexAttribPointer(_positionY, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(_positionY);
    glVertexAttribPointer(_normalY, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(_normalY);
    glVertexAttribPointer(_texCoordY, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void*)(6 * sizeof(float)));
    glEnableVertexAttribArray(_texCoordY);

    glGenVertexArrays(1, &lightVAO);
    glBindVertexArray(lightVAO);
    // 只需要绑定VBO不用再次设置VBO的数据，因为箱子的VBO数据中已经包含了正确的立方体顶点数据
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    // 设置灯立方体的顶点属性（对我们的灯来说仅仅只有位置数据）
    glVertexAttribPointer(_LpositionY, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(_LpositionY);
    
    glUseProgram(_programY);
   
    //////////////////
//    M3DVector3f amb_1 = {1.0f, 0.5f, 0.31f};
//    M3DVector3f diff_1 = {1.0f, 0.5f, 0.31f};
//    M3DVector3f spe_1 = {0.5f, 0.5f, 0.5f};
   // glUniform3fv(_amb, 1, amb_1);
//    glUniform3fv(_diff, 1, diff_1);
//    glUniform3fv(_spe, 1, spe_1);
//    glUniform1f(_shine, 64.0);
    
    /* 根据时间变化  去改变颜色
    double cur_time = timeutil::getCurrentTime();

    M3DVector3f lightColor;
    M3DVector3f diffuseColor,ambientColor;
    lightColor[0] =  sin(cur_time * 2.0f);
    lightColor[1] =  sin(cur_time * 0.7f);
    lightColor[2] =  sin(cur_time * 1.3f);
    m3dVector3Multiply(diffuseColor, lightColor, a_light); // decrease the influence
    m3dVector3Multiply(ambientColor,diffuseColor , a_light); // low influence
    */
    glUniform3fv(_fangxiang, 1, cameraTarget);
    glUniform1f(_cutoff, cos(12.5));
//     M3DVector3f directionL = {-2.0,-1.0,-0.3};
//    glUniform3fv(_direction, 1, directionL);
    
    M3DVector3f a_light = {0.1,0.1,0.1};
    M3DVector3f d_light = {0.8,0.8,0.8};
    M3DVector3f spe_light = {1.0,1.0,1.0};
    glUniform3fv(_ambLight, 1, a_light);
    glUniform3fv(_diffLight, 1, d_light);
    glUniform3fv(_speLight, 1, spe_light);
    // 漫反射贴图
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture0);
    glUniform1i(_diff, 0);
//    镜面光贴图
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, texture1);
    glUniform1i(_tex1, 1);
    // 反射贴图
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, texture2);
    glUniform1i(_emission_tex, 2);

    glUniform1f(glGetUniformLocation(_programY, "d"), 1.0);
    glUniform1f(glGetUniformLocation(_programY, "k1"), 0.09);
    glUniform1f(glGetUniformLocation(_programY, "k2"), 0.032);

    M3DMatrix44f _model;
    m3dLoadIdentity44(_model);
    M3DMatrix44f _model_copy;
    m3dLoadIdentity44(_model_copy);
    // scale
    M3DMatrix44f s;
    m3dLoadIdentity44(s);
    m3dScaleMatrix44(s, 0.5,0.5,0.5);
    m3dCopyMatrix44(_model_copy, _model);
    m3dMatrixMultiply44(_model, s, _model_copy);
    //    // rotate
    M3DMatrix44f r_matrix_init;
    m3dRotationMatrix44(r_matrix_init, m3dDegToRad(redius_z),  1.0, 0.3, 0.5);
    m3dCopyMatrix44(_model_copy, _model);
    m3dMatrixMultiply44(_model, r_matrix_init, _model_copy);
    redius_z += 2.0;
    //    // tran
    M3DMatrix44f translation_init;
    m3dLoadIdentity44(translation_init);
    m3dTranslationMatrix44(translation_init,-0.0,0.0,0.);
    m3dCopyMatrix44(_model_copy, _model);
    m3dMatrixMultiply44(_model, translation_init, _model_copy);
    
    glUniformMatrix4fv(_v, 1, GL_FALSE,mViewMatrix);
    glUniformMatrix4fv(_p, 1, GL_FALSE,mProjection);
    glUniformMatrix4fv(_m, 1, GL_FALSE, _model);
    M3DMatrix44f inverse_model_;
    M3DMatrix44f trans_inverse_model_;
    M3DMatrix33f timodel33;
    
    m3dLoadIdentity44(inverse_model_);
    m3dLoadIdentity44(trans_inverse_model_);
    m3dInvertMatrix44(inverse_model_, _model);
    m3dLoadIdentity33(timodel33);
    for (int i=0; i<4; i++) {
        for (int j=0; j<4; j++) {
            trans_inverse_model_[i*4+j]=inverse_model_[j*4+i];
        }
    }
    int ind[]={0,1,2,4,5,6,8,9,10};
    for (int i=0; i<9; i++) {
        timodel33[i]=trans_inverse_model_[ind[i]];
    }
    glUniformMatrix3fv(_timodel, 1, 0, timodel33);
    
    glBindVertexArray(VAO);
    glDrawArrays(GL_TRIANGLES, 0, 36);

    glBindVertexArray(0);
    glUseProgram(0);
    
//    glUseProgram(_LprogramY);
//    //
//    M3DMatrix44f _Lmodel;
//    m3dLoadIdentity44(_Lmodel);
//    M3DMatrix44f _Lmodel_copy;
//    m3dLoadIdentity44(_Lmodel_copy);
//    // scale
//    M3DMatrix44f Ls;
//    m3dLoadIdentity44(Ls);
//    m3dScaleMatrix44(Ls, 0.2,0.2,0.2);
//    m3dCopyMatrix44(_Lmodel_copy, _Lmodel);
//    m3dMatrixMultiply44(_Lmodel, Ls, _Lmodel_copy);
//        // rotate
//    M3DMatrix44f Lr_matrix_init;
//    m3dRotationMatrix44(Lr_matrix_init, m3dDegToRad(-45.0),  1.0, 0.0, 0.0);
//    m3dCopyMatrix44(_Lmodel_copy, _Lmodel);
//    m3dMatrixMultiply44(_Lmodel, Lr_matrix_init, _Lmodel_copy);
//    //    redius_z += 1.0;
//    M3DMatrix44f Ltranslation_init;
//    m3dLoadIdentity44(Ltranslation_init);
//    m3dTranslationMatrix44(Ltranslation_init, 0.0, 2.0f, 0.0);
//    m3dCopyMatrix44(_Lmodel_copy, _Lmodel);
//    m3dMatrixMultiply44(_Lmodel, Ltranslation_init, _Lmodel_copy);
//
//    glUniformMatrix4fv(_Lm, 1, GL_FALSE, _Lmodel);
//    glUniformMatrix4fv(_Lp, 1, GL_FALSE,mProjection);
//    glUniformMatrix4fv(_Lv, 1, GL_FALSE,mViewMatrix);
//    glBindVertexArray(lightVAO);
//    glDrawArrays(GL_TRIANGLES, 0, 36);
//    glBindVertexArray(0);
//    glUseProgram(0);
    
    [_cont presentRenderbuffer:_renderBuffer];
    
}

@end

