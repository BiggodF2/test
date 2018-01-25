
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



void WardBRDF(  Material mat,
				DirLight L,
				float3	position,//顶点位置
				float3	normal,
				float3	toEye,//"顶点->眼"向量 
				out 	float4 ambient,
				out		float4 diffuse,
				out		float4 specular)
{
	ambient  = float4(0.f,0.f,0.f,0.f);
	diffuse  = float4(0.f,0.f,0.f,0.f);
	specular = float4(0.f,0.f,0.f,0.f);
	////顶点到眼
	float3 viewDirection = normalize(toEye);
	//Roughness in Brush Direction
	float _AlphaX = 1.0;
	float _AlphaY = 0.1;//Roughness in Brush Direction粗超度方向刷
	//////计算切点向量
	float3 T = normalize(cross(normal,toEye));	
	//////计算光照方向：顶点->光源
	float3 vertexToLightSource = L.dir;
	////	
	//////光的距离
	float distance = length(L.dir);
	//float attenuation = 1.0/distance;
	float3 lightDirection = normalize(vertexToLightSource);

	//半角
	float3	halfwayVector = normalize(lightDirection + toEye);

	float3 	binormalDirection = cross(normal,T);

	float dotLN = dot(lightDirection, normal);
	ambient = L.ambient * mat.diffuse;
	diffuse = L.ambient*mat.diffuse*max(0.0, dotLN);
	if(dotLN > 0.0)
	{
		float dotHN = dot(halfwayVector,normal);
		float dotVN = dot(toEye, normal);
		float dotHTAlphaX = 
		dot(halfwayVector, T )/ _AlphaX;
		float dotHBAlphaY = 
		dot(halfwayVector,binormalDirection)/ _AlphaY;
		specular = mat.specular
		*sqrt(max(0.0, dotLN/dotVN))
		*exp(-2.0*(dotHTAlphaX*dotHTAlphaX
		+dotHBAlphaY*dotHBAlphaY)/(1.0 + dotHN));
	}
}


