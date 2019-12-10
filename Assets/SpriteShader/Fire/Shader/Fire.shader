Shader "JokerShen/Fire"
{
	Properties
	{
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1,1,1,1)
		_GrayFactor("GrayFactor",Range(0,1))=1
		_SmoothColor("SmoothColor",color)=(0,0,1,1)
		_FromColor("FromColor",color)=(1,0,0,1)
		[Toggle]_VerticalDirection("VerticalDir",int)=0

		[MaterialToggle] PixelSnap("Pixel snap", Float) = 0
	}

		SubShader
		{
			Tags
			{
				"Queue" = "Transparent"
				"IgnoreProjector" = "True"
				"RenderType" = "Transparent"
				"PreviewType" = "Plane"
				"CanUseSpriteAtlas" = "True"
			}

			Cull Off
			Lighting Off
			ZWrite Off
			Blend One OneMinusSrcAlpha

			Pass
			{
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile _ PIXELSNAP_ON
				#include "UnityCG.cginc"

				struct appdata_t
				{
					float4 vertex   : POSITION;
					float4 color    : COLOR;
					float2 texcoord : TEXCOORD0;
				};

				struct v2f
				{
					float4 vertex   : SV_POSITION;
					fixed4 color : COLOR;
					float2 texcoord  : TEXCOORD0;
				};

				fixed4 _Color;

				v2f vert(appdata_t IN)
				{
					v2f OUT;
					OUT.vertex = UnityObjectToClipPos(IN.vertex);
					OUT.texcoord = IN.texcoord;
					OUT.color = IN.color * _Color;
					#ifdef PIXELSNAP_ON
					OUT.vertex = UnityPixelSnap(OUT.vertex);
					#endif
					

					return OUT;
				}

				float random(float2 uv)
				{
					return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453123);
				}

				float noise(float2 uv)
				{
					// 获取 uv 的整数部分       
					float2 i = floor(uv);

					// 获取 uv 的小数部分 
					float2 f = frac(uv);

					// 获取 uv 的相邻坐标 
					float a = random(i);
					float b = random(i + float2(1.0, 0.0));
					float c = random(i + float2(0.0, 1.0));
					float d = random(i + float2(1.0, 1.0));

					// 对 uv 的小数部分进行 smoothstep
					// 因为是小数部分，所以肯定是小于 1 
					// 所以去掉了对 smoothstep 的 step 操作
					// 只保留了 smooth 的过程 
					float2 u = f * f * (3 - 2 * f);

					return lerp(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
				}

				sampler2D _MainTex;
				sampler2D _AlphaTex;
				float _AlphaSplitEnabled;
				float _GrayFactor;
				fixed4 _SmoothColor;
				fixed4 _FromColor;
				int _VerticalDirection;

				fixed4 SampleSpriteTexture(float2 uv)
				{
					fixed4 texColor = tex2D(_MainTex, uv);
					float randomNum1 = noise(uv * 16 - _Time.y * 10 * float2(0, 1));
					float randomNum2 = noise(uv * 16 - _Time.y * 5 * float2(0, 1));
					float fireNoise = randomNum1 + randomNum2;
					//fireNoise = fireNoise * pow(1 - uv.y, 3);
					fireNoise = pow(fireNoise, 5);
					fireNoise = (1 + fireNoise * pow(1 - uv.y, 3)) * pow(1 - uv.y, 3);
					
					fixed3 fireColor = lerp(fixed3(1, 0, 0), fixed3(1, 1, 0), pow( 1-uv.y,6)*fireNoise);
					fixed4 fire = fixed4(fireColor*fireNoise,1);
					fixed4 color = lerp(texColor, fire, fireNoise);
	#if UNITY_TEXTURE_ALPHASPLIT_ALLOWED
					if (_AlphaSplitEnabled)
						color.a = tex2D(_AlphaTex, uv).r;
	#endif //UNITY_TEXTURE_ALPHASPLIT_ALLOWED

					return color;
				}

				fixed4 frag(v2f IN) : SV_Target
				{
					fixed4 c = SampleSpriteTexture(IN.texcoord) * IN.color;
					c.rgb *= c.a;
					return c;
				}
			ENDCG
			}
		}
}
