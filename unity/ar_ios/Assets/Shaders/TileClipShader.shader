Shader "Custom/TileClipShader"
{
    Properties
    {
        _BaseMap ("Texture", 2D) = "white" {}
        _BaseColor ("Color", Color) = (1,1,1,1)
        _Rotation ("Rotation", Float) = 0
        _TileWidth ("Tile Width", Float) = 0.6
        _TileHeight ("Tile Height", Float) = 0.6
        _OffsetX ("Offset X", Float) = 0
        _OffsetZ ("Offset Z", Float) = 0
        _CenterX ("Center X", Float) = 0
        _CenterZ ("Center Z", Float) = 0
        _GroutColor ("Grout Color", Color) = (0.6, 0.6, 0.6, 1)
        _GroutSize ("Grout Size", Float) = 0.05
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Geometry"
        }
        
        LOD 100
        Cull Off
        ZWrite On
        ZTest LEqual
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            
            // Multi-compile for mobile optimization
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float fogFactor : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                float4 _QuadPoint0;
                float4 _QuadPoint1;
                float4 _QuadPoint2;
                float4 _QuadPoint3;
                float _Rotation;
                float _TileWidth;
                float _TileHeight;
                float _OffsetX;
                float _OffsetZ;
                float _CenterX;
                float _CenterZ;
                half4 _GroutColor;
                float _GroutSize;
            CBUFFER_END
            
            // Simplified point-in-polygon test for mobile
            bool IsInsideQuad(float2 testPos)
            {
                // Manual unroll for better mobile performance
                float2 p0 = _QuadPoint0.xz;
                float2 p1 = _QuadPoint1.xz;
                float2 p2 = _QuadPoint2.xz;
                float2 p3 = _QuadPoint3.xz;
                
                bool inside = false;
                
                // Test edge 0->1
                if (((p0.y > testPos.y) != (p1.y > testPos.y)) &&
                    (testPos.x < (p1.x - p0.x) * (testPos.y - p0.y) / (p1.y - p0.y) + p0.x))
                {
                    inside = !inside;
                }
                
                // Test edge 1->2
                if (((p1.y > testPos.y) != (p2.y > testPos.y)) &&
                    (testPos.x < (p2.x - p1.x) * (testPos.y - p1.y) / (p2.y - p1.y) + p1.x))
                {
                    inside = !inside;
                }
                
                // Test edge 2->3
                if (((p2.y > testPos.y) != (p3.y > testPos.y)) &&
                    (testPos.x < (p3.x - p2.x) * (testPos.y - p2.y) / (p3.y - p2.y) + p2.x))
                {
                    inside = !inside;
                }
                
                // Test edge 3->0
                if (((p3.y > testPos.y) != (p0.y > testPos.y)) &&
                    (testPos.x < (p0.x - p3.x) * (testPos.y - p3.y) / (p0.y - p3.y) + p3.x))
                {
                    inside = !inside;
                }
                
                return inside;
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                
                output.positionHCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
                
                return output;
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                // Get world position in XZ plane
                float2 worldPosXZ = input.positionWS.xz;
                
                // Clip pixels outside the quad
                if (!IsInsideQuad(worldPosXZ))
                {
                    discard;
                }

                float2 worldOffset = worldPosXZ - float2(_OffsetX, _OffsetZ);

                float2 centered = worldOffset - float2(_CenterX, _CenterZ);

                // Rotate UVs around center (0.5, 0.5)
                float rad = _Rotation * 3.14159265 / 180.0;
                float cosA = cos(rad);
                float sinA = sin(rad);
                float2 rotated = float2(cosA * centered.x - sinA * centered.y,         // rotate
                                        sinA * centered.x + cosA * centered.y);

                float2 uv = rotated / float2(_TileWidth, _TileHeight);

                float2 uvFrac = frac(uv);
                bool isGrout = uvFrac.x < _GroutSize || uvFrac.y < _GroutSize;
                
                // Sample texture
                half4 texColor = isGrout
                      ? _GroutColor
                      : SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvFrac);
                half4 color = texColor * _BaseColor;
                
                // Apply fog
                color.rgb = MixFog(color.rgb, input.fogFactor);
                
                return color;
            }
            ENDHLSL
        }
        
        // Shadow caster pass for mobile
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off
            
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            
            ENDHLSL
        }
        
        // Depth-only pass for mobile
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            
            ZWrite On
            ColorMask 0
            Cull Off
            
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            
            ENDHLSL
        }
    }
    
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
