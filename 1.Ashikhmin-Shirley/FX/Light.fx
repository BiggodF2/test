
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


void AhikhminDirctionLight(  Material mat,
				DirLight L,
				float3	position,//顶点位置
				float3	normal,
				float3	toEye,//"顶点->眼"向量
				float3 eyePos,
				out 	float4 ambient,
				out		float4 diffuse,
				out		float4 specular
				)
{

	//初始化  
    ambient  = float4(0.f,0.f,0.f,0.f);
	diffuse  = float4(0.f,0.f,0.f,0.f);
	specular = float4(0.f,0.f,0.f,0.f);
	//计算光照方向：顶点->光源
	float3 vertexToLightSource = L.dir;
	//归一化光线方向
	float3 lightDirection = normalize(vertexToLightSource);//vertexToLightSource
	float pi = 3.1415926535;
	ambient = mat.ambient * L.ambient;
	float Nu = 10;
	float Nv = 10000;
	float3 tangent  =  normalize( cross( normal, toEye ) );
	float3 bitangent = normalize( cross( normal, tangent) );
	float3 H = normalize(toEye + lightDirection);
	float dotNL = max(dot(normal,lightDirection),0.0);
	float dotNV = max(dot(normal,toEye),0.0);
	float HdotN = max(dot(normal,H),0.0);
	float dotVH = max(dot(toEye,H),0.0);
	float HdotL = max(dot(H,lightDirection),0.0);
	float HdotB = dot(H, bitangent);
	float HdotT = dot(H, tangent);
	if(dotNL > 0.0)
	{
	diffuse = (28.0*mat.diffuse) / (23.0*pi)
		*(1.0-mat.specular)
		*(1.0 -pow(1.0-dotNV/2.0,5.0))
		*(1.0 -pow(1.0-dotNL/2.0,5.0));
	
	float f = 10.0;  //根据材质不同f不同
    float4 fresnelCoe = mat.specular + (1 - mat.specular)*pow(1.0 - HdotL, 5.0);////fresnel 反射系数  
	
	float ps_num_exp = Nu * HdotT * HdotT + Nv * HdotB * HdotB;
	ps_num_exp /= (1.0 - HdotN * HdotN);

	float Ps_num = sqrt((HdotN + 1) * (Nv + 1));
	Ps_num *= pow(HdotN, ps_num_exp);

	float Ps_den = 8.0 * 3.14159 * HdotL;
	Ps_den *= max(HdotL, HdotL);

	specular = (Ps_num / Ps_den);
	specular *= (mat.specular + (1.0 - mat.specular) * pow(1.0 - HdotL, 5.0));
	}
	
}
