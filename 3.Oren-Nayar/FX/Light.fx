
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

void  OrenNayarDirctionLight(  Material mat,//只对iffuse处理，相对于lambert模型，会随着视角不同出项阴影
				DirLight L,
				float3	position,//顶点位置
				float3	normal,
				float3	toEye,//"顶点->眼"向量,
				out 	float4 ambient,
				out		float4 diffuse,
				out		float4 specular
				)
{
	//初始化  
    ambient  = float4(0.f,0.f,0.f,0.f);
	diffuse  = float4(0.f,0.f,0.f,0.f);
	specular = float4(0.f,0.f,0.f,0.f);

	float roughness = 10.0f;
	float4 lightColor = L.diffuse + L.ambient + L.specular;
	const float PI = 3.1415926;

	float dotNL = dot(normal, L.dir);
	float dotNV = dot(normal, toEye);

	float angleVN = acos(dotNV);
	float angleLN = acos(dotNL);

	float alpha = max(angleVN, angleLN);
	float beta = min(angleVN, angleLN);
	float gamma = dot(toEye - normal *dot(toEye,normal),L.dir-normal*dot(L.dir,normal));
	float roughnessSquared = roughness*roughness;

	float A = 1.0 - 0.5*(roughnessSquared / (roughnessSquared + 0.57));
	float B = 0.45 * (roughnessSquared / (roughnessSquared + 0.09));
    float C = sin(alpha) * tan(beta);

	float L1 = max(0.0, dotNL)*(A + B * max(0.0, gamma)*C);
	diffuse = L.diffuse * L1;
	ambient = L.ambient * mat.ambient;
	specular = L.specular * mat.specular;

}


