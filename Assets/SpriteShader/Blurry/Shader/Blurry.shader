﻿Shader "JokerShen/Blurry"
{
	Properties
	{
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1,1,1,1)
		_GrayFactor("GrayFactor",Range(0,1))=1
		_SmoothColor("SmoothColor",color)=(0,0,1,1)
		_FromColor("FromColor",color)=(1,0,0,1)
		[Toggle]_VerticalDirection("VerticalDir",int)=0

		_BlurDistance("BlurDistance",Range(0,5))=1

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

				sampler2D _MainTex;
				sampler2D _AlphaTex;
				half4 _MainTex_TexelSize;
				float _AlphaSplitEnabled;
				float _GrayFactor;
				fixed4 _SmoothColor;
				fixed4 _FromColor;
				int _VerticalDirection;
				float _BlurDistance;

				fixed4 SampleSpriteTexture(float2 uv)
				{
					fixed4 color = tex2D(_MainTex, uv);
					float grayColor = color.r * 0.299 + color.g * 0.587 + color.b * 0.114;
					color = lerp(color,fixed4(grayColor,grayColor,grayColor,1),_GrayFactor);
					float lerpDir = lerp(uv.x,uv.y,_VerticalDirection);
					color = lerp(_FromColor,_SmoothColor,lerpDir)*color;

					//实现模糊
					_BlurDistance *= _MainTex_TexelSize.x;
					color = color*4 
					+ (tex2D(_MainTex,fixed2(uv.x- _BlurDistance,uv.y)))
					+(tex2D(_MainTex,fixed2(uv.x+ _BlurDistance,uv.y)))
					+(tex2D(_MainTex,fixed2(uv.x,uv.y- _BlurDistance)))
					+(tex2D(_MainTex,fixed2(uv.x,uv.y+ _BlurDistance)));

					color *= 0.125;

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
