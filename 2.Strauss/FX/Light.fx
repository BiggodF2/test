
//平行光
struct DirLight
{
	float4	ambient;	//环境光
	float4	diffuse;	//漫反射光
	float4	specular;	//高光

	float3	dir;		//方向
	float	unused;		//“4D向量”对齐用
};

//点光源
struct PointLight
{
	float4	ambient;	//环境光
	float4	diffuse;	//漫反射光
	float4	specular;	//高光

	float3	pos;		//光源位置
	float	range;		//光源照射范围

	float3	att;		//光强衰减系数
	float	unused;		//"4D向量"对齐用
};

//聚光灯
struct SpotLight
{
	float4	ambient;	//环境光
	float4	diffuse;	//漫反射光
	float4	specular;	//高光

	float3	dir;		//方向
	float	range;		//照射范围

	float3	pos;		//位置
	float	spot;		//聚光强度系数

	float3	att;		//误差系数
	float	theta;		//最大发散角度
};

//材质
struct Material
{
	float4	ambient;
	float4	diffuse;
	float4	specular;	//specular中第4个元素代表材质的表面光滑程度
};

void  StraussDirctionLight(  Material mat,
				DirLight L,
				float3	position,//顶点位置
				float3	normal,
				float3	toEye,//"顶点->眼"向量,
				out 	float4 ambient,
				out		float4 diffuse,
				out		float4 specular)
{
	//初始化  
    ambient  = float4(0.f,0.f,0.f,0.f);
	diffuse  = float4(0.f,0.f,0.f,0.f);
	specular = float4(0.f,0.f,0.f,0.f);

	float fSmoothness = 0.6;
	float fMetalness = 0.2;
	float fTransparency = 0.1;
	float3 n = normalize(normal);
	float3 l = normalize(L.dir);
	float3 v = normalize(toEye);
	float3 h = reflect(l, n);
	float Kf = 1.12;
	float Ks = 1.01;
	float NdotL = dot(n,l);
	float NdotV = dot(n, v);
	float HdotV = dot(h, v);
	float fNdotL = (1.0/pow(NdotL-Kf, 2.0) - 1.0/(Kf*Kf))
		/(1.0/pow(1.0-Kf,2.0)-1.0/(Kf*Kf));
	float s_cubed = pow(fSmoothness,3.0);

	float d  = ( 1.0f - fMetalness * fSmoothness ); 
	float Rd = (1.0f - s_cubed)*(1.0f - fTransparency);
	diffuse.xyz = NdotL * d * Rd * mat.diffuse.xyz;

	float r = (1.0f - fTransparency)-Rd;
	float j = fNdotL 
		* (1.0/pow(1.0-Ks,2.0) - 1.0/pow(NdotL-Ks,2.0))/(1.0/pow(1.0-Ks,2.0)-1.0/(Ks*Ks))
		* (1.0/pow(1.0-Ks,2.0) - 1.0/pow(NdotL-Ks,2.0))/(1.0/pow(1.0-Ks,2.0)-1.0/(Ks*Ks));

	// 'k' is used to provide small off-specular
	// peak for very rough surfaces. Can be changed  to suit desired results... 
	const float k = 0.1f;
	float reflect = min(1.0f, r + j * (r + k));

	float3 C1 = float3(1.0f, 1.0f, 1.0f);
	float3 Cs = C1 + fMetalness * (1.0f - fNdotL) * (mat.diffuse.xyz-C1);

	specular.xyz = Cs * reflect * pow(-HdotV, 3.0/(1.0f - fSmoothness));

	diffuse.xyz = max(0.0f, diffuse);
	specular.xyz = max(0.0f, specular);
	diffuse.w = 1.0f;
	specular.w = 1.0f;
	ambient = mat.ambient * L.ambient;

}
