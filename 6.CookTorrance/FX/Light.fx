
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


void CookTorrance(Material mat,
				DirLight l,  
				float3 position,
				float3 normal,
				float3 toEye,//"顶点->眼"向量  
				out float4 ambient,
				out float4 diffuse, 
				out float4 specular)  
{  
    //初始化  
    ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);  
    diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);  
    specular = float4(0.0f, 0.0f, 0.0f, 0.0f);  
  
    float3 P = position.xyz;  
    float3 N = normal.xyz;  
  
  
    //光照方向与光源方向相反  
    float3 lightVec = -l.dir;  
    float3 L = normalize(lightVec);  
    //处理环境光数值  
    ambient = mat.ambient*l.ambient;  
  
  
    float nl = max(dot(L, N), 0);  
    //计算漫反射  
    diffuse = nl * mat.diffuse * l.diffuse;  
      
    // Cook-Torrance 光照模型渲染  
    float3 V = toEye;  
    float3 H = normalize(L + V);  
  
    float nv = dot(N, V);  
    if (nv > 0 && nl > 0)  
    {  
        float nh = dot(N, H);  
        float m = 0.3;  
        float temp = (nh*nh - 1) / (m*m*nh*nh);  
        float roughness = (exp(temp)) / (pow(m, 2)*pow(nh, 4));//粗糙度，根据 beckmann 函数  
  
        float vh = dot(V, H);  
        float a = (2 * nh*nv) / vh;  
        float b = (2 * nh*nl) / vh;  
        float geometric = min(a, b);  
        geometric = min(1, geometric);//几何衰减系数  
  
        float f = 0.125;  
        float fresnelCoe = f + (1 - f)*pow(1 - vh, 5);////fresnel 反射系数  
        float rs = (fresnelCoe*roughness*geometric) / (nv*nl);  
        specular = rs * nl * mat.specular * l.specular;  
    }  
}
