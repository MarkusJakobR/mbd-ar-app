Shader "Custom/TileClipShader"
{
    Properties
    {
        _BaseMap ("Texture", 2D) = "white" {}
        _BaseColor ("Color", Color) = (1,1,1,1)
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        
        Pass
        {
            Cull Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float4 _QuadPoint0;
                float4 _QuadPoint1;
                float4 _QuadPoint2;
                float4 _QuadPoint3;
            CBUFFER_END
            
            // Point-in-polygon test
            bool IsInsideQuad(float2 testPos)
            {
                float2 poly[4];
                poly[0] = _QuadPoint0.xz;
                poly[1] = _QuadPoint1.xz;
                poly[2] = _QuadPoint2.xz;
                poly[3] = _QuadPoint3.xz;
                
                bool inside = false;
                int j = 3;
                
                for (int i = 0; i < 4; i++)
                {
                    if (((poly[i].y > testPos.y) != (poly[j].y > testPos.y)) &&
                        (testPos.x < (poly[j].x - poly[i].x) * (testPos.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x))
                    {
                        inside = !inside;
                    }
                    j = i;
                }
                
                return inside;
            }
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }
            
            half4 frag(Varyings IN) : SV_Target
            {
                // Check if this pixel is inside the quad
                float2 worldPosXZ = IN.worldPos.xz;
                
                if (!IsInsideQuad(worldPosXZ))
                {
                    discard; // Don't render this pixel
                }
                
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                return color * _BaseColor;
            }
            ENDHLSL
        }
    }
    
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
